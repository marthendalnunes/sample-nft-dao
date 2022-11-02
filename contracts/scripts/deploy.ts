import { ethers, run } from 'hardhat'
require('dotenv').config({ path: '.env' })
import { CRYPTO_DEVS_NFT_CONTRACT_ADDRESS } from '../constants'
const BLOCk_CONFIRMATIONS_WAIT = 6

async function main() {
  const NFTMarketplace = await ethers.getContractFactory('NFTMarketplace')
  const nftMarketplace = await NFTMarketplace.deploy()
  await nftMarketplace.deployTransaction.wait(BLOCk_CONFIRMATIONS_WAIT)

  await run(`verify:verify`, {
    address: nftMarketplace.address
  })
  console.log('NFTMarketplace deployed to: ', nftMarketplace.address)

  const CryptoDevsDAO = await ethers.getContractFactory('CryptoDevsDAO')
  const cryptoDevsDAO = await CryptoDevsDAO.deploy(
    nftMarketplace.address,
    CRYPTO_DEVS_NFT_CONTRACT_ADDRESS,
    {
      value: ethers.utils.parseEther('0.1')
    }
  )
  await cryptoDevsDAO.deployTransaction.wait(BLOCk_CONFIRMATIONS_WAIT)
  await run(`verify:verify`, {
    address: cryptoDevsDAO.address
  })
  console.log('cryptoDevsDAO deployed to: ', cryptoDevsDAO.address)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
