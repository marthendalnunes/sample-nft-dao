// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

interface INFTMarketplace {
  function getPrice() external view returns (uint256);

  function available(uint256 _tokenId) external view returns (bool);

  function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
  function balanceOf(address owner) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256);
}

contract CryptoDevsDAO is Ownable {
  struct Proposal {
    uint256 nftTokenId;
    uint256 deadline;
    uint256 yayVotes;
    uint256 nayVotes;
    bool executed;
    mapping(uint256 => bool) voters;
  }

  enum Vote {
    YAY,
    NAY
  }

  mapping(uint256 => Proposal) public proposals;
  uint256 public numProposals;

  INFTMarketplace nftMarketplace;
  ICryptoDevsNFT cryptoDevsNFT;

  constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = INFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
  }

  modifier nftHolderOnly() {
    require(cryptoDevsNFT.balanceOf(msg.sender) > 0, 'Not a DAO Member');
    _;
  }

  modifier activeProposalOnly(uint256 proposalIndex) {
    require(
      proposals[proposalIndex].deadline > block.timestamp,
      'Proposal has expired'
    );
    _;
  }

  modifier inactiveProposalOnly(uint256 proposalIndex) {
    require(
      proposals[proposalIndex].deadline <= block.timestamp,
      'Proposal not expired'
    );
    require(
      proposals[proposalIndex].executed == false,
      'Proposal already executed'
    );
    _;
  }

  function createProposal(uint256 _nftTokenId)
    external
    nftHolderOnly
    returns (uint256)
  {
    require(nftMarketplace.available(_nftTokenId), 'NFT not for sale');
    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;
    proposal.deadline = block.timestamp + 5 minutes;

    numProposals++;
    return numProposals - 1;
  }

  function voteOnProposal(uint256 proposalIndex, Vote vote)
    external
    nftHolderOnly
    activeProposalOnly(proposalIndex)
  {
    Proposal storage proposal = proposals[proposalIndex];
    uint256 voterNftBalance = cryptoDevsNFT.balanceOf(msg.sender);
    uint256 numVotes;

    for (uint256 i = 0; i < voterNftBalance; i++) {
      uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
      if (proposal.voters[tokenId] == false) {
        numVotes++;
        proposal.voters[tokenId] = true;
      }
    }
    require(numVotes > 0, 'ALready Voted');
    if (vote == Vote.YAY) {
      proposal.yayVotes += numVotes;
    } else {
      proposal.nayVotes += numVotes;
    }
  }

  function executeProposal(uint256 proposalIndex)
    external
    nftHolderOnly
    inactiveProposalOnly(proposalIndex)
  {
    Proposal storage proposal = proposals[proposalIndex];
    if (proposal.yayVotes > proposal.nayVotes) {
      uint256 nftPrice = nftMarketplace.getPrice();
      require(address(this).balance >= nftPrice, 'Not enough funds');
      nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }
    proposal.executed = true;
  }

  function withdrawEther() external payable onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  receive() external payable {}

  fallback() external payable {}
}
