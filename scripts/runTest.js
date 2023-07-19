const { ethers } = require('ethers');
const verifyABI = require("../artifacts/contracts/ecdsaverificationcontract.sol/ECDSAVerificationContract.json").abi

const verifierContractAddress = '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1'; // Replace with the ECDSA verification contract address


// Provider and Signer
const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545/'); // Replace with the actual RPC provider URL
const privateKey = '0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0'; // Replace with the private key of the account
const wallet = new ethers.Wallet(privateKey, provider);

// Contract instance
const contract = new ethers.Contract(verifierContractAddress, verifyABI, wallet);

// Function inputs
const privateKey1 = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'; // Replace with the private key of the first player
const privateKey2 = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'; // Replace with the private key of the second player
const wallet1 = new ethers.Wallet(privateKey1, provider);
const wallet2 = new ethers.Wallet(privateKey2, provider);
const tokenIDs = ['1', '2']; // Replace with actual token IDs
const minters = ['0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f', '0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f']; // Replace with actual minter addresses
const players = [wallet1.address, wallet2.address]; // Replace with actual player addresses

// Generate the signatures
async function generateSignatures() {
    try {

        // Generate the nonces for the players
        const nonce = await contract.getNonce(players[0], players[1]);

        const firstHashedMessage = ethers.utils.solidityKeccak256(
            ['uint256[2]', 'address[2]', 'address[2]', 'uint256', 'bool'], [tokenIDs, minters, players, nonce, false]
        );

        const secondHashedMessage = ethers.utils.solidityKeccak256(
            ['uint256[2]', 'address[2]', 'address[2]', 'uint256', 'bool'], [tokenIDs, minters, players, nonce, true]
        );

        const firstSignature = await wallet1.signMessage(ethers.utils.arrayify(firstHashedMessage));
        const secondSignature = await wallet2.signMessage(ethers.utils.arrayify(firstHashedMessage));
        const thirdSignature = await wallet2.signMessage(ethers.utils.arrayify(secondHashedMessage));

        console.log('Signatures:');
        console.log('Signature 1:', firstSignature);
        console.log('Signature 2:', secondSignature);
        console.log('Signature 3:', thirdSignature);

        const signatures = [
            firstSignature,
            secondSignature,
            thirdSignature
        ]

        try {
            const result = await contract.verify(signatures, tokenIDs, minters, players);
            await result.wait()
            console.log('Verify function executed successfully');
        } catch (error) {
            console.error(error);
        }

    } catch (error) {
        console.error(error);
    }
}

generateSignatures();