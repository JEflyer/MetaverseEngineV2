//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

contract ManagementContract {
    mapping (address => bool) public platformAddresses;
    mapping (address => bool) public minterAddresses;
    address[] public platforms;
    address[] public minters;

    address public multiSignatureWallet;

    constructor(address multiSig){
        multiSignatureWallet = multiSig;
    }

    modifier onlyMultiSig{
        require(msg.sender == multiSignatureWallet,"ERR:Not Multi Sig Wallet");
        _;
    }

    function addPlatformAddress(address platform) external onlyMultiSig {
        platformAddresses[platform] = true;
        platforms.push(platform);
    }

    function removePlatformAddress(address platform) external onlyMultiSig {
        platformAddresses[platform] = false;
        removeFromArrayInStorage(platforms, platform);
    }

    function addMinterAddress(address minter) external onlyMultiSig {
        minterAddresses[minter] = true;
        minters.push(minter);
    }

    function removeMinterAddress(address minter) external onlyMultiSig {
        minterAddresses[minter] = false;
        removeFromArrayInStorage(minters, minter);
    }

    function removeFromArrayInStorage(address[] storage arr, address toRemove) private {
        for(uint256 i = 0; i < arr.length; i++){
            if(arr[i] == toRemove){
                delete arr[i];
                arr[i] = arr[arr.length -1];
                arr.pop();
                break;
            }
        }
    }
}
