//SPDX-License-Identifier: GLWTPL
//GLWTPL == Good Luck With That Public License == Best Opensource License Name
pragma solidity 0.8.15;

contract MultiSigWallet {

    //Events that will be emitted through this contract 
    event Submission(uint indexed transactionId);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);

    //A definition of the Transaction struct
    struct Transaction {
        address destination; // The address that will be called
        uint voted; // The number of votes for that have been cast for this vote
        bytes data; // The data that will be passed to the destination address
        bool executed;// To track whether the transaction has already been executed or not
    }

    //An array of all transactions
    //Index of Transaction struct is the transactionId
    Transaction[] public transactions;

    //For a given transaction ID check whether a signer has voted for it or not
    mapping (uint => mapping (address => bool)) public confirmations;

    // For a given address store a boolean value to check if they are allowed to sign or not
    mapping(address => bool) public canConfirm;

    // Store the number of signers
    uint256 public numOfSigners;

    // The constuctor is only called on instantiation of the contract
    // For the purpose of simplicity we only set the signers on deployment, production would have different functionality
    constructor(address[] memory signers){

        //Iterate through the given signers
        for(uint i = 0; i < signers.length;i++){

            //Check that each signer is not null
            require(signers[i] != address(0),"ERR:NS");//NS => Null Signer
            
            //Set the signer as allowed to confirm transactions
            canConfirm[signers[i]] = true;
        }
        //Set the number of signers as the length of the array of given signers
        numOfSigners = signers.length;
    }

    //This modifier is attached to multiple functions & checks that the caller is approved in the canConfirm mapping as an approved signer
    modifier onlySigner{
        //This part is ran before the code in the function that the modifier is attached to
        require(canConfirm[msg.sender],"ERR:NS");//NS => Not Signer

        //This is to say that the remainder of the code in the function the modifier is attached to can now run
        _;

        //You could also place conditional logic here to run after the function has finished if you needed to
    }

    // This function can only be called by a signer
    // This function will submit a transaction to be executed
    // destination => The address that will be having a call made to
    // data => The description of the function being called + the input parameters being sent
    // external => This means that the function can only be called from out side of this contract  
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

    // This function can only be called by a signer
    // This function will confirm a transaction to be executed
    // transactionId => The ID of the transaction to confirm
    // external => This means that the function can only be called from out side of this contract  
    function confirmTransaction(uint transactionId) external onlySigner {

        //Check that the transaction has not been executed already
        require(transactions[transactionId].executed == false, "Transaction has already been executed");
        
        //Check that the caller has not already confirmed
        require(confirmations[transactionId][msg.sender] == false,"ERR:AV");//AV => Already Voted
        
        //Set the caller as having confirmed
        confirmations[transactionId][msg.sender] = true;

        //Increment the number of confirmations in the transaction ID
        transactions[transactionId].voted++;

        //Emit event
        emit Confirmation(msg.sender, transactionId);
    }

    // This function can only be called by a signer
    // This function will confirm a transaction to be executed
    // transactionId => The ID of the transaction to confirm
    // external => This means that the function can only be called from out side of this contract  
    function executeTransaction(uint transactionId) external onlySigner {

        // Check that the transaction has not already been executed
        require(transactions[transactionId].executed == false, "Transaction has already been executed");

        // Check that all signers have signed
        require(transactions[transactionId].voted == numOfSigners,"ERR:Not Enough Votes");
        
        // Retrieve a storage pointer to the transaction struct
        Transaction storage txn = transactions[transactionId];
 
        // Set the transaction as executed 
        txn.executed = true;

        // Call the destination address passing in the data specifying what the function call is & what parameters are being sent
        (bool success, ) = txn.destination.call(txn.data);

        //If the transaction was successful
        if (success)

            //Emit event
            emit Execution(transactionId);

        else {

            //Emit event
            emit ExecutionFailure(transactionId);
            
            //Set the transaction as not executed
            txn.executed = false;
        }
    }

    // This function can only be called by a signer
    // This function will revoke confirmation that a transaction is to be executed
    // transactionId => The ID of the transaction to revoke confirmation of 
    // external => This means that the function can only be called from out side of this contract
    function revokeConfirmation(uint transactionId) external onlySigner {

        //Check that the caller has signed for the transaction
        require(confirmations[transactionId][msg.sender] == true, "Transaction not confirmed by sender");
        
        //Set the caller as having revoked confirmation
        confirmations[transactionId][msg.sender] = false;

        //Decrement the number of votes for the transaction
        transactions[transactionId].voted--;

        //Emit event
        emit Revocation(msg.sender, transactionId);
    }

    // This function can be called by any wallet or contract other than this contract
    // This function will return whether the caller has confirmed a transaction or not
    // transactionId => The ID of the transaction to check confirmation for
    // external => This means that the function can only be called from out side of this contract
    // view => This means that the function does not modify any state, so it can be called from outside the contract
    function isConfirmed(uint transactionId) external view returns (bool) {
        return confirmations[transactionId][msg.sender];
    }
}
