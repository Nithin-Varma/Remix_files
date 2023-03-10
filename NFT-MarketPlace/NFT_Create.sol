//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address contractAddress;

    constructor(address marketPlaceAddress) ERC721("Nithin", "NIT") {
        contractAddress = marketPlaceAddress;
    }

    function createToken(string memory tokenURI) public returns(uint) {
        _tokenIds.increment();
        uint newToken = _tokenIds.current();
        _mint(msg.sender, newToken);
        _setTokenURI(newToken, tokenURI);
        setApprovalForAll(contractAddress, true);

        return newToken;
    }

}