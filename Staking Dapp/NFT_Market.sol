//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private TotalItems;
    Counters.Counter private SoldItems;

    address private owner;

    uint listingPrice = 0.0001 ether;
   // This is paid by the seller when listing an NFT.

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketDetails {
        uint ID;
        uint tokenId;
        address NFTAddress;
        address payable seller;
        address payable owner;
        uint price;
        bool SoldOut;
    }

    mapping(uint256 => MarketDetails) private idToMarketDetails;

    event MarketCreated(uint indexed ID, uint indexed tokenId, 
                        address indexed NFTAddress, address seller,
                        address owner, uint price, bool SoldOut);

    function getlistingprice() public view returns(uint) {
        return listingPrice;
    }

    function CreateMarketItem(uint tokenId, address NFTAddress, uint price) 
              public payable nonReentrant {
                  require(price>0, "price should be more than zero.");
                  require(msg.value == listingPrice, "price should be equal to the listingPrice.");

                  TotalItems.increment();
                  uint ID = TotalItems.current();

                  idToMarketDetails[ID] = MarketDetails(
                      ID,
                      tokenId,
                      NFTAddress,
                      payable(msg.sender),
                      payable(address(0)),
                      price,
                      false
                  );
                  IERC721(NFTAddress).transferFrom(msg.sender, address(this), tokenId);
                  emit MarketCreated(
                      ID,
                      tokenId,
                      NFTAddress,
                      msg.sender,
                      address(0),
                      price,
                      false
                      
                  );

    }


    function createMarketforSale(address NFTAddress, uint ID)
            public payable nonReentrant {
                uint price = idToMarketDetails[ID].price;
                uint tokenId = idToMarketDetails[ID].tokenId;
                require(msg.value == price, "Please pay the listingPrice before listing NFT for sale.");

                idToMarketDetails[ID].seller.transfer(msg.value);
                IERC721(NFTAddress).transferFrom(address(this), msg.sender, tokenId);

                idToMarketDetails[ID].owner = payable(msg.sender);
                idToMarketDetails[ID].SoldOut = true;

                SoldItems.increment();
                payable(owner).transfer(listingPrice);
    }


}