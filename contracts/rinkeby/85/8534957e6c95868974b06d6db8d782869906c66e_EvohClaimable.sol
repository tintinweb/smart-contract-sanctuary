pragma solidity 0.8.3;

import "./EvohERC721.sol";

contract EvohClaimable is EvohERC721 {

    uint256 public maxTotalSupply;
    address public owner;
    uint256 public startTime;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxTotalSupply,
        uint256 _startTime
    )
        EvohERC721(_name, _symbol)
    {
        owner = msg.sender;
        maxTotalSupply = _maxTotalSupply;
        startTime = _startTime;
    }

    /**
        @notice Claim an NFT
     */
    function claim()
        external
    {
        require(block.timestamp >= startTime, "Cannot claim before start time");
        uint256 claimed = totalSupply;
        require(maxTotalSupply > claimed, "All NFTs claimed");

        addOwnership(msg.sender, claimed);
        emit Transfer(address(0), msg.sender, claimed);
        totalSupply = claimed + 1;
    }

     /**
        @notice Submit NFT hashes on-chain.
        @param _indexes Indexes of the hashes being added.
        @param _hashes IPFS hashes being added.
     */
    function submitHashes(
        uint256[] calldata _indexes,
        string[] calldata _hashes
    ) external {
        require(_indexes.length == _hashes.length);
        for (uint256 i = 0; i < _indexes.length; i++) {
            tokenURIs[_indexes[i]] = _hashes[i];
        }
    }
}