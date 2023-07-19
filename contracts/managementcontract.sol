//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

contract ManagementContract {

    // Stores whether an address is an approved platform address
    mapping (address => bool) public platformAddresses;

    // Stores whether an address is an approved NFT minter address 
    mapping (address => bool) public minterAddresses;

    //Stores a list of all current allowed platforms
    address[] public platforms;

    //Stores a list of all current allowed NFT minters
    address[] public minters;

    //Stores the address of the multi signature wallet for making changes
    address public multiSignatureWallet;

    //The constructor will only be called on deployment of the contract
    // multiSig => The address of the multi signature contract 
    constructor(address multiSig){
        multiSignatureWallet = multiSig;
    }

    //A modifier for checking that the caller is the multi signature contract
    modifier onlyMultiSig{
        require(msg.sender == multiSignatureWallet,"ERR:Not Multi Sig Wallet");
        _;
    }

    // Only the multi signature contract can call this function
    // This function is used to add a platform address to the ecosystem
    function addPlatformAddress(address platform) external onlyMultiSig {

        //Set the address as an approved address
        platformAddresses[platform] = true;

        //Add the address to the array of approved platform addresses
        platforms.push(platform);
    }

    // Only the multi signature contract can call this function
    // This function is used to remove a platform address from the ecosystem
    function removePlatformAddress(address platform) external onlyMultiSig {

        //Revoke the addresses approval
        platformAddresses[platform] = false;

        //Delete the address from the array of approved platform addresses
        removeFromArrayInStorage(platforms, platform);
    }

    // Only the multi signature contract can call this function
    // This function is used to add a NFT minter address to the ecosystem
    function addMinterAddress(address minter) external onlyMultiSig {
        
        //Add the address as an approved address
        minterAddresses[minter] = true;

        //Add the address to the array of approved NFT minter addresses
        minters.push(minter);
    }

    // Only the multi signature contract can call this function
    // This function is used to remove a minter address from the ecosystem
    function removeMinterAddress(address minter) external onlyMultiSig {

        //Revoke the approval of the NFT minter address 
        minterAddresses[minter] = false;

        //Remove the address from the array of approved NFT minter addresses
        removeFromArrayInStorage(minters, minter);
    }

    // This function will only be called by this contract
    // arr => Is an reference pointer to a slot in storage containing the array being edited
    // toRemove => This is the address being removed from the array 
    function removeFromArrayInStorage(address[] storage arr, address toRemove) private {

        //Iterate over the array
        for(uint256 i = 0; i < arr.length; i++){
            
            //If the current value at index i matches the address being removed
            if(arr[i] == toRemove){

                // Delete the current index
                delete arr[i];

                //Replace the current index with the last index in the array
                arr[i] = arr[arr.length -1];

                //Destroy the last index in the array
                arr.pop();

                //Break the for loop
                break;
            }
        }
    }
}
