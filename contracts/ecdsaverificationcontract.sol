//SPDX-License-Identifier: GLWTPL
pragma solidity 0.8.15;

//Using the ECDSA library
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//Using the standard ERC721 interface
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//An interface of the functions on the stats contract that this contract will interact with
interface IStats {
    function incrementWins(uint256 tokenID, address minter) external;

    function incrementLosses(uint256 tokenID, address minter) external;
}

//An interface of the functions on the management contract that this contract will interact with
interface IManagement {
    // Code being accessed
    // mapping (address => bool) public platformAddresses;
    function platformAddresses(address) external view returns(bool);

    // Code being accessed
    // mapping (address => bool) public minterAddresses;
    function minterAddresses(address) external view returns(bool);
}

contract ECDSAVerificationContract  {

    // A nested mapping storing a nonce for 2 given addresses
    mapping (address => mapping(address  => uint)) public nonces;

    // The address of the stats contract
    address statsContract;

    // The address of the management contract
    address managementContract;

    //Called only on deployment of the contract
    constructor(address stats, address management){

        //Set management contract address in storage
        managementContract = management;

        //Set stats contract address in storage
        statsContract = stats;
    }


    function verify(bytes[3] memory signatures, uint256[2] memory tokenIDs, address[2] memory minters,address[2] memory players) external  {

        //Check that the caller is an allowed platform address
        require(IManagement(managementContract).platformAddresses(msg.sender),"ERR:NotAllowedPlatform");

        //Check that the minter addresses are allowed minter addresses
        require(IManagement(managementContract).minterAddresses(minters[0]) && IManagement(managementContract).minterAddresses(minters[1]),"ERR:NotAllowedMinter");

        //Check that the players do own the NFTs being played with
        require(IERC721(minters[0]).ownerOf(tokenIDs[0]) == players[0],"ERR:Minter does not own token");
        require(IERC721(minters[1]).ownerOf(tokenIDs[1]) == players[1],"ERR:Minter does not own token");

        //Retrieve the current nonce for the 2 player addresses
        uint nonce = nonces[players[0]][players[1]];
        
        //Create first hashed message as a combination of the tokenIDs, minter addresses, player addresses, 
        //the nonce for the player combination & a false boolean to state that this is the start of the game
        bytes32 firstHashedMessage = keccak256(abi.encodePacked(
            tokenIDs,
            minters,
            players,
            nonce,
            false
        ));

        //Create the same hashed message but with a true boolean instead to signify that this is the end of the game
        bytes32 secondHashedMessage = keccak256(abi.encodePacked(
            tokenIDs,
            minters,
            players,
            nonce,
            true
        ));

        //Check that the first player is the signer of the first signature using the first hashed message
        bool checkFirst = verifySignature(players[0], firstHashedMessage, signatures[0]);
        require(checkFirst,"ERR:FS");//FS => First Signature

        //Check that the second player is the signer of the second signature using the first hashed message
        bool checkSecond = verifySignature(players[1], firstHashedMessage, signatures[1]);
        require(checkSecond,"ERR:SS");//SS => Second Signer

        //Create the signedMessageHash for the second hashed message, essentially just prepending "\x19Ethereum Signed Message:\n32"
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(secondHashedMessage);

        //Retrieve the players address from the message & third signature
        address winner = ECDSA.recover(messageHash, signatures[2]);

        //Declare the winning & losing variables 
        uint256 winningTokenID;
        address winningMinter;
        
        uint256 losingTokenID;
        address losingMinter;

        //If the winner is the first player
        if(winner == players[0]){

            //Set the winning variables to the first players details
            winningMinter = minters[0];
            winningTokenID = tokenIDs[0];

            //Set the losing variables to the second players details
            losingMinter = minters[1];
            losingTokenID = tokenIDs[1];

        //If the winner is the second player
        }else if(winner == players[1]){
            //Set the winning variables to the second players details
            winningMinter = minters[1];
            winningTokenID = tokenIDs[1];

            //Set the losing variables to the first players details
            losingMinter = minters[0];
            losingTokenID = tokenIDs[0];

        //If no match was found revert
        }else {

            revert("ERR:InvalidWinner");
        }

        //Increment the nonce both ways
        nonces[players[0]][players[1]]++;
        nonces[players[1]][players[0]]++;

        //Call the increment losses function on the stats contract for the losing player
        IStats(statsContract).incrementLosses(losingTokenID,losingMinter);

        //Call the increment wins function on the stats contract for the winning player
        IStats(statsContract).incrementWins(winningTokenID,winningMinter);

    }

    //This function verifies that for a given signature a given signer signed a hashed message
    //This function can only be called by this contract
    function verifySignature(address signer, bytes32 hash, bytes memory signature) private pure returns (bool) {
        
        //Prepend "\x19Ethereum Signed Message:\n32" to the hashed message
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(hash);

        //Recover the signer address
        address recoveredSigner = ECDSA.recover(messageHash, signature);
        
        //Return the result of the condition check that the recovered signer address is the given signer
        return recoveredSigner == signer;
    }

    //A view function to retrieve the nonce for a given pair of addresses
    //This function can only be called from outside of this contract
    //view => This means that this function only views storage variables & does not change them
    function getNonce(address a, address b) external view returns(uint256){
        return nonces[a][b];
    }
}
