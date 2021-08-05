/**
 *Submitted for verification at Etherscan.io on 2020-06-27
*/

pragma solidity ^0.6.0;

contract BrandContest {

    //The allowed Votes that can be transfered
    mapping(uint256 => uint256) private _allowedVotingAmounts;

    //Keeps track of the current ERC721 Token addresses allowed for this votation (ARTE/ETRA)
    mapping(address => bool) private _allowedTokenAddresses;

    //Takes notes of how many votes received for any token id, for both Tokens (ARTE/ETRA)
    mapping(address => mapping(uint256 => uint256)) private _votes;

    //Takes notes of how many ethers received for any token id, for both Tokens (ARTE/ETRA)
    mapping(address => mapping(uint256 => uint256)) private _ethers;

    //Il blocco di fine della votazione
    uint256 private _surveyEndBlock;

    //Event raised only the first time this NFT receives a vote
    event FirstVote(address indexed tokenAddress, uint256 indexed tokenId);

    //Event raised when someone votes for a specific NFT
    event Vote(address indexed voter, address indexed tokenAddress, uint256 indexed tokenId, address creator, uint256 votes, uint256 amount);

    //To let this Smart Contract work, you need to pass the ERC721 token addresses supported by this survey (ARTE/ETRA).
    constructor(address[] memory allowedTokenAddresses, uint256 surveyEndBlock) public {
        for(uint256 i = 0; i < allowedTokenAddresses.length; i++) {
            _allowedTokenAddresses[allowedTokenAddresses[i]] = true;
        }
        _surveyEndBlock = surveyEndBlock;
        _allowedVotingAmounts[4000000000000000] = 1;
        _allowedVotingAmounts[30000000000000000] = 5;
        _allowedVotingAmounts[100000000000000000] = 10;
        _allowedVotingAmounts[300000000000000000] = 20;
    }

    //The concrete vote operation:
    //You vote sending some ether to this call, specifing the ERC721 location and id you want to vote.
    //The amount of ethers received will be registered as a vote for the chosen NFT and transfered to its creator
    //The vote is to be considered valid if and only if the creator's address is the one who sent the original NFT to the wallet with address: 0x74Ef70357ef21BaD2b45795679F2727C48d501ED
    function vote(address tokenAddress, uint256 tokenId, address payable creator) public payable {

        //Are you still able to vote?
        require(block.number < _surveyEndBlock, "Survey ended!");

        //To vote you must provide some ethers, with a maximum of 3 eth
        require(_allowedVotingAmounts[msg.value] > 0, "Vote must be 0.004, 0.03, 0.1 or 0.3 ethers");

        //You can just vote one of the allowed NFTs (ARTE/ETRA)
        require(_allowedTokenAddresses[tokenAddress], "Unallowed Token Address!");

        //Check if tokenId and its owner are valid
        require(IERC721(tokenAddress).ownerOf(tokenId) != address(0), "Owner is nobody, maybe wrong tokenId?");

        //If this is the first time this NFT receives a vote, the FirstVote event will be raised
        if(_votes[tokenAddress][tokenId] == 0) {
            emit FirstVote(tokenAddress, tokenId);
        }

        //Update the votes and ethers amount for this NFT
        _votes[tokenAddress][tokenId] = _votes[tokenAddress][tokenId] + _allowedVotingAmounts[msg.value];
        _ethers[tokenAddress][tokenId] = _ethers[tokenAddress][tokenId] + msg.value;

        //Transfer the received ethers to the NFT's creator
        creator.transfer(msg.value);

        //Raise an event containing voting info, to let everyone grab this info off-chain
        emit Vote(msg.sender, tokenAddress, tokenId, creator, _allowedVotingAmounts[msg.value], msg.value);
    }

    //Utility function to let everyone know (both offchain and onchain) the current votes amount for every allowed NFT (ARTE/ETRA)
    function votesOf(address tokenAddress, uint256 tokenId) public view returns(uint256, uint256) {
        return (_votes[tokenAddress][tokenId], _ethers[tokenAddress][tokenId]);
    }

    function getSurveyEndBlock() public view returns(uint256) {
        return _surveyEndBlock;
    }
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}