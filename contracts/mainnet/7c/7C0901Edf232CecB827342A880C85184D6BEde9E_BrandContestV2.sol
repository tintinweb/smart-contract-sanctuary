// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract BrandContestV2 {
    uint256 private _startBlock;
    uint256 private _endBlock;

    address private _votingTokenAddress;
    address private _nftTokenAddress;

    uint256[] private _candidates;
    mapping(uint256 => bool) _isCandidate;

    uint256 private _singleVoteAmount;
    uint256 private _singleVoteAmountToBurn;

    mapping(address => bool) private _voted;
    mapping(address => bool) private _redeemed;
    mapping(address => uint256) private _voters;
    mapping(uint256 => uint256) private _votes;

    uint256 private _toBurn;

    bool private _burnt;

    constructor(
        uint256 startBlock,
        uint256 endBlock,
        address votingTokenAddress,
        address nftTokenAddress,
        uint256[] memory candidates,
        uint256 singleVoteAmount,
        uint256 singleVoteAmountToBurn
    ) {
        _startBlock = startBlock;
        _endBlock = endBlock;
        _votingTokenAddress = votingTokenAddress;
        _nftTokenAddress = nftTokenAddress;
        _candidates = candidates;
        for(uint256 i = 0; i < candidates.length; i++) {
            _isCandidate[candidates[i]] = true;
        }
        _singleVoteAmount = singleVoteAmount;
        _singleVoteAmountToBurn = singleVoteAmountToBurn;
    }

    function startBlock() public view returns (uint256) {
        return _startBlock;
    }

    function endBlock() public view returns (uint256) {
        return _endBlock;
    }

    function votingTokenAddress() public view returns (address) {
        return _votingTokenAddress;
    }

    function nftTokenAddress() public view returns (address) {
        return _nftTokenAddress;
    }

    function candidates() public view returns (uint256[] memory) {
        return _candidates;
    }

    function isCandidate(uint256 tokenId) public view returns (bool) {
        return _isCandidate[tokenId];
    }

    function singleVoteAmount() public view returns (uint256) {
        return _singleVoteAmount;
    }

    function singleVoteAmountToBurn() public view returns (uint256) {
        return _singleVoteAmountToBurn;
    }

    function votes(uint256 tokenId) public view returns (uint256) {
        return _votes[tokenId];
    }

    function voted(address voter) public view returns (bool, uint256) {
        return (_voted[voter], _voters[voter]);
    }

    function burnt() public view returns (bool) {
        return _burnt;
    }

    function toBurn() public view returns (uint256) {
        return _toBurn;
    }

    function redeemed(address voter) public view returns (bool) {
        return _redeemed[voter];
    }

    function vote(uint256 tokenId) public {
        require(block.number >= _startBlock, "Survey not yet started");
        require(block.number <= _endBlock, "Survey has ended");
        require(!_voted[msg.sender], "User Already Voted");
        require(
            _isCandidate[tokenId],
            "The chosen tokenId is not concurring in the challenge"
        );
        IERC20(_votingTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _singleVoteAmount
        );
        _voters[msg.sender] = tokenId;
        _voted[msg.sender] = true;
        _votes[tokenId] = _votes[tokenId] + 1;
        _toBurn += _singleVoteAmountToBurn;
    }

    function redeemVotingTokens(address voter) public {
        require(block.number >= _startBlock, "Survey not yet started");
        require(block.number >= _endBlock, "Survey is still running");
        require(_voted[voter], "Your address did not vote");
        require(!_redeemed[voter], "This voter already redeemed his stake");
        _redeemed[voter] = true;
        IERC20(_votingTokenAddress).transfer(
            voter,
            _singleVoteAmount - _singleVoteAmountToBurn
        );
    }

    function burn() public {
        require(block.number >= _startBlock, "Survey not yet started");
        require(block.number >= _endBlock, "Survey is still running");
        require(!_burnt, "Already burnt");
        IERC20(_votingTokenAddress).burn(_toBurn);
        _burnt = true;
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;
}