//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

contract StatsContract {

    //A struct definition which tracks the number of wins & losses
    struct Stats {
        uint wins;
        uint losses;
    }

    // A nested mapping which stores an instancde of the Stats struct for a given NFT minter address & a given token ID 
    mapping (address => mapping(uint256 => Stats)) public stats;

    //The address of the signature verification contract
    address public signatureVerifier;

    //The address of the deployer of the contract
    address private deployer;

    //Can only be called on deployment of the contract
    constructor(){

        //Set the deployer as the address deploying the contract
        deployer = msg.sender;
    }

    //A modifier that can be attached to multiple functions
    //This modifier checks that the caller of the function is the signature verifier
    modifier onlyVerfier{
        require(msg.sender == signatureVerifier,"ERR:NV");//NV => Not Verifier
        _;
    }

    //This function can only be called once
    //This function can only be called by the deployer
    // sigVerifier => The address of the ECDSA signature verifying contract
    // external => This function can only be called by wallets & contracts that are not this contract
    function init(address sigVerifier) external {

        //Check tha the caller is the deployer
        require(msg.sender == deployer,"ERR:ND");//ND => Not Deployer
        
        //Check that the signatureVerifier address has not been set before
        require(signatureVerifier == address(0),"ERR:AS");//AS => Already Set

        //Set the sigVerfier address in storage
        signatureVerifier = sigVerifier;
    }

    //This function is called by the signature verifier contract
    // tokenID => The token ID on the NFT minter
    // minter => The address of the NFT minter 
    function incrementWins(uint256 tokenID, address minter) external onlyVerfier {
        
        //In the stats mapping for the given minter address & token ID increment the number of wins
        stats[minter][tokenID].wins++;
    }

    //This function is called by the signature verifier contract
    // tokenID => The token ID on the NFT minter
    // minter => The address of the NFT minter 
    function incrementLosses(uint256 tokenID, address minter) external onlyVerfier {

        //In the stats mapping for the given minter address & token ID increment the number of losses
        stats[minter][tokenID].losses++;
    }

    //This function can be called by anyone
    //This function returns the number of wins & losses for a given token ID from a given NFT minter
    //external => This function can not be called by this contract, only from sources outside of this contract
    function getStats(uint256 tokenID, address minter) external view returns (uint wins, uint losses) {
        return (stats[minter][tokenID].wins, stats[minter][tokenID].losses);
    }
}
