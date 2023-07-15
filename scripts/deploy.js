const ethers = require("ethers")
const { abi: multiSigABI, bytecode: multiSigBytecode } = require("../artifacts/contracts/multisigwallet.sol/MultiSigWallet.json")
const { abi: managementABI, bytecode: managementBytecode } = require("../artifacts/contracts/managementcontract.sol/ManagementContract.json")
const { abi: verifyABI, bytecode: verifyBytecode } = require("../artifacts/contracts/ecdsaverificationcontract.sol/ECDSAVerificationContract.json")
const { abi: statsABI, bytecode: statsBytecode } = require("../artifacts/contracts/statscontract.sol/StatsContract.json")
const { abi: NFTABI, bytecode: NFTBytecode } = require("../artifacts/contracts/testnftcontract.sol/TestNFTContract.json")


const RPC = "http://127.0.0.1:8545/"
const provider = new ethers.providers.JsonRpcProvider(RPC)

const deployerPrivate = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
const deployerWallet = new ethers.Wallet(deployerPrivate, provider)

const signer1Private = "0x701b615bbdfb9de65240bc28bd21bbc0d996645a3dd57e7b12bc2bdf6f192c82"
const signer1Wallet = new ethers.Wallet(signer1Private, provider)

const signer2Private = "0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897"
const signer2Wallet = new ethers.Wallet(signer2Private, provider)

const signer3Private = "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"
const signer3Wallet = new ethers.Wallet(signer3Private, provider)

const platformPrivate = "0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0"
const platformWallet = new ethers.Wallet(platformPrivate, provider)

const multiSigFactory = new ethers.ContractFactory(multiSigABI, multiSigBytecode, deployerWallet)
const managementFactory = new ethers.ContractFactory(managementABI, managementBytecode, deployerWallet)
const verifyFactory = new ethers.ContractFactory(verifyABI, verifyBytecode, deployerWallet)
const statsFactory = new ethers.ContractFactory(statsABI, statsBytecode, deployerWallet)
const NFTFactory = new ethers.ContractFactory(NFTABI, NFTBytecode, deployerWallet)

function log(message) {
    console.log(message)
}

async function start() {
    log("Deploying contracts")
    const multiSig = await multiSigFactory.deploy([signer1Wallet.address, signer2Wallet.address, signer3Wallet.address])
    await multiSig.deployed()

    const management = await managementFactory.deploy(multiSig.address)
    await management.deployed()

    const stats = await statsFactory.deploy()
    await stats.deployed()

    const verify = await verifyFactory.deploy(stats.address)
    await verify.deployed()

    let tx1 = await stats.init(verify.address)
    await tx1.wait()

    const nft = await NFTFactory.deploy()
    await nft.deployed()

    console.log(`MultiSig address: ${multiSig.address}`)
    console.log(`Management address: ${management.address}`)
    console.log(`Stats address: ${stats.address}`)
    console.log(`Verify address: ${verify.address}`)
    console.log(`NFT address: ${nft.address}`)


    //-------ADDING MINTER TO ECOSYSTEM
    log("ADDING MINTER TO ECOSYSTEM")
    const functionSignature = 'addMinterAddress(address)';
    const abiCoder = new ethers.utils.AbiCoder();
    const data = abiCoder.encode(['address'], [nft.address]);
    const calldata = ethers.utils.hexlify(ethers.utils.concat([
        ethers.utils.hexZeroPad(management.interface.getSighash(functionSignature), 4),
        data,
    ]));

    log("Submitting transaction")
        //Submit the NFT contract address to the multisig to be added to the stats contract
    let tx2 = await (new ethers.Contract(multiSig.address, multiSigABI, signer1Wallet)).submitTransaction(management.address, calldata)
    await tx2.wait()

    log("Signing 1")
        //Sign the transaction in the multisig wallet for each signer
    let sign1 = await (new ethers.Contract(multiSig.address, multiSigABI, signer1Wallet)).confirmTransaction(0)
    await sign1.wait()
    log("Signing 2")
    let sign2 = await (new ethers.Contract(multiSig.address, multiSigABI, signer2Wallet)).confirmTransaction(0)
    await sign2.wait()
    log("Signing 3")
    let sign3 = await (new ethers.Contract(multiSig.address, multiSigABI, signer3Wallet)).confirmTransaction(0)
    await sign3.wait()

    log("Executing")
        //Execute the transaction
    let ex1 = await (new ethers.Contract(multiSig.address, multiSigABI, signer1Wallet)).executeTransaction(0)
    await ex1.wait()


    //-------ADDING PLATFORM TO ECOSYSTEM
    log("ADDING PLATFORM TO ECOSYSTEM")
    const functionSignature2 = 'addPlatformAddress(address)';
    const data2 = abiCoder.encode(['address'], [platformWallet.address]);
    const calldata2 = ethers.utils.hexlify(ethers.utils.concat([
        ethers.utils.hexZeroPad(management.interface.getSighash(functionSignature2), 4),
        data2,
    ]));

    log("Submitting transaction")
        //Submit the NFT contract address to the multisig to be added to the stats contract
    let tx3 = await (new ethers.Contract(multiSig.address, multiSigABI, signer1Wallet)).submitTransaction(management.address, calldata2)
    await tx3.wait()

    log("Signing 1")
        //Sign the transaction in the multisig wallet for each signer
    let sign4 = await (new ethers.Contract(multiSig.address, multiSigABI, signer1Wallet)).confirmTransaction(1)
    await sign4.wait()
    log("Signing 2")
    let sign5 = await (new ethers.Contract(multiSig.address, multiSigABI, signer2Wallet)).confirmTransaction(1)
    await sign5.wait()
    log("Signing 3")
    let sign6 = await (new ethers.Contract(multiSig.address, multiSigABI, signer3Wallet)).confirmTransaction(1)
    await sign6.wait()

    //Execute the transaction
    log("Executing")
    let ex2 = await (new ethers.Contract(multiSig.address, multiSigABI, signer1Wallet)).executeTransaction(1)
    await ex2.wait()

    //Mint 2 NFTs, 1 to each player

    const privateKey1 = '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d'; // Replace with the private key of the first player
    const privateKey2 = '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'; // Replace with the private key of the second player
    const wallet1 = new ethers.Wallet(privateKey1, provider);
    const wallet2 = new ethers.Wallet(privateKey2, provider);

    log("Minting token 1 to player 1")
    let mint1 = await nft.mint(wallet1.address, 1)
    await mint1.wait()

    log("Minting token 2 to player 2")
    let mint2 = await nft.mint(wallet2.address, 2)
    await mint2.wait()

}

start()