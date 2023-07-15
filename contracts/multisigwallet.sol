//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

contract MultiSigWallet {

    event Submission(uint indexed transactionId);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);

    struct Transaction {
        address destination;
        uint voted;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;

    mapping(address => bool) public canConfirm;
    uint256 public numOfSigners;

    constructor(address[] memory signers){
        for(uint i = 0; i < signers.length;i++){
            require(signers[i] != address(0),"ERR:NS");//NS => Null Signer
            canConfirm[signers[i]] = true;
        }
        numOfSigners = signers.length;
    }

    modifier onlySigner{
        require(canConfirm[msg.sender],"ERR:NS");//NS => Not Signer
        _;
    }

    function submitTransaction(address destination, bytes memory data)
        external
        onlySigner
    {
        uint transactionId = transactions.length;
        transactions.push(Transaction({
            destination: destination,
            voted: 0,
            data: data,
            executed: false
        }));
        emit Submission(transactionId);
    }

    function confirmTransaction(uint transactionId) external onlySigner {
        require(transactions[transactionId].executed == false, "Transaction has already been executed");
        require(confirmations[transactionId][msg.sender] == false,"ERR:AV");//AV => Already Voted
        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].voted++;
        emit Confirmation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId) external onlySigner {
        require(transactions[transactionId].executed == false, "Transaction has already been executed");
        require(transactions[transactionId].voted == numOfSigners,"ERR:Not Enough Votes");
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        (bool success, ) = txn.destination.call(txn.data);
        if (success)
            emit Execution(transactionId);
        else {
            emit ExecutionFailure(transactionId);
            txn.executed = false;
        }
    }

    function revokeConfirmation(uint transactionId) external onlySigner {
        require(confirmations[transactionId][msg.sender] == true, "Transaction not confirmed by sender");
        confirmations[transactionId][msg.sender] = false;
        transactions[transactionId].voted--;
        emit Revocation(msg.sender, transactionId);
    }

    function isConfirmed(uint transactionId) external view returns (bool) {
        return confirmations[transactionId][msg.sender];
    }
}
