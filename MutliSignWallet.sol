//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract MultiSignWallet {


    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(address indexed owner,uint indexed txIndex,
                            address indexed to,uint value,bytes data);
    event ConfirmTransaction(address indexed owner,uint indexed txIndex);
    event RevokeTransaction(address indexed owner,uint indexed txIndex);
    event ExecuteTransaction(address indexed owner,uint indexed txIndex);

    address[] public owner;
    mapping(address=>bool) public isOwner;
    uint public numConformationsRequired;
    
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an Owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exists");
        _;
    }

    modifier notExecuted(uint _txIndex){
        require(!transactions[_txIndex].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Teansaction already executed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired){
        require(_owners.length>0, "owners cant be zero");
        require(_numConfirmationsRequired>0 && _numConfirmationsRequired<=_owners.length, "invalid number of required confirmations in constructor");
        for(uint i=0; i<_owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid Owner");
            require(!isOwner[owner], "owner cant be duplicate");
            isOwner[owner] = true;
        }
        numConformationsRequired = _numConfirmationsRequired;
    }

    receive() external payable{
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        ++transaction.numConfirmations;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    } 

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations:0
        })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations>numConformationsRequired, "something went wrong");
        transaction.executed = true;
        (bool success,) = transaction.to.call{value:transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, _txIndex);

    }

    function revokeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");
        --transaction.numConfirmations;

        emit RevokeTransaction(msg.sender, _txIndex);
    }

    function getowners() public view returns(address[] memory){
        return owner;
    }

    function Transactions_length() public view returns(uint) {
        return transactions.length;
    }

    function getTransactions(uint _txIndex) public view returns(address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        Transaction storage transaction = transactions[_txIndex];
        return( transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations);
    }
}
