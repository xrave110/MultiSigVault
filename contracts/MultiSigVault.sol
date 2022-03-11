// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "OpenZeppelin/openzeppelin-contracts@4.5.0/contracts/access/Ownable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.5.0/contracts/access/AccessControl.sol";

contract MultiSigVault is Ownable, AccessControl {
    
    //ROLES
    //bytes32 public constant DEPLOYER = keccak256("DEPLOYER"); //
    bytes32 public constant SIGNER = keccak256("SIGNER"); //
    uint256 private startTime;
    address[] public addressesToSign;
    uint256 approvalsLimit;
    
    struct Transfer{
        address payable _to;
        uint _amount;
        uint _txId;
        address[] _signatures;
    }
    
    address[] signature;
    Transfer[] public transactionLog;

    constructor(){
        approvalsLimit = 1;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SIGNER, msg.sender);
    }
    
    event depositDone(uint amount, address indexed depositedTo); //indexed (used for search and query)
    
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        require(DEFAULT_ADMIN_ROLE != role, "Cannot add admin role");
        approvalsLimit += 1;
        super._grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        require(DEFAULT_ADMIN_ROLE != role, "Cannot add admin role");
        require(account == msg.sender, "You cannot revoke role from your own account");
        approvalsLimit -= 1;
        super._revokeRole(role, account);
    }
     /**
     * @dev Deposits native currency into the smart contract.
     *
     * Requirements:
     * - Everyone can deposit
     */
    function deposit() public payable returns (uint){ //paybale allows to use msg.value
        emit depositDone(msg.value, msg.sender);
        return address(this).balance; // contract reflects the address
    }
    
    function removeTransaction(uint txId) private{
        for(uint i = txId; i < transactionLog.length - 1; i++){
            transactionLog[i] = transactionLog[i + 1];
        }
        transactionLog.pop();
    }
    
     /**
     * @dev Withdraws native currency from the smart contract.
     *
     * Requirements:
     * - All signature of the signers are required
     */
    function withdraw(uint txId) public payable onlyRole(SIGNER) returns (uint){
        //msg.sender is a payable address
        /* 
        address payable toSend = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        toSend.transfer(amount); */
        require(txId < transactionLog.length);
        address payable toSend = transactionLog[txId]._to;
        require(address(this).balance >= transactionLog[txId]._amount, "You do not have enough funds");
        require(approvalsLimit <= transactionLog[txId]._signatures.length, "You do not have enough signatures");
        toSend.transfer(transactionLog[txId]._amount); // the safest way to withdraw because of built error handlings (revert commend as for required)
        removeTransaction(txId);
        return address(this).balance;
    }
    
    /**
     * @dev 
     *
     * Function allows to withdraw small amounts of funds per 1 day
     * Requirements:
     * - 1 day must be elapsed since last witdrawal
     * - only small numbers of ETH (0.02)
     */
    function withdrawWithTimeConstraints(uint256 amount) public payable onlyRole(SIGNER) returns (uint){
        require(address(this).balance >= amount, "You do not have enough funds");
        require(amount < 2*(10**16), "Too big amount");
        require(block.timestamp > startTime + 20 seconds, "Not enough time passed since last withdrawal");
        startTime = block.timestamp;
        payable(msg.sender).transfer(amount);
        return address(this).balance;
    }

    function getBalance() public view returns (uint){
        return address(this).balance; // contract reflects the address
    }
    
    function addTransaction(address payable _to, uint _amount) external payable onlyRole(SIGNER){
        transactionLog.push(Transfer(_to, _amount, transactionLog.length, signature));
    }

    function approve(uint txId) public onlyRole(SIGNER){
        bool approveAllowed = true;
        for(uint j; j < transactionLog[txId]._signatures.length; j++){
            if(msg.sender == transactionLog[txId]._signatures[j]){
                approveAllowed = false;
                break;
            }
        }
        require(approveAllowed == true, "You already signed the transaction");
        transactionLog[txId]._signatures.push(msg.sender);
    }
}