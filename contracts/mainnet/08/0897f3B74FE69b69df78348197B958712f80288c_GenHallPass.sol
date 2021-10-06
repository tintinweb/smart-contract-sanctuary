// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface IGenHall {
    function getTokenInfo(uint256 _tokenId)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            bytes32
        );

    function getTokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

contract GenHallPass is ERC721Enumerable, Ownable {
    using Strings for uint256;

    struct Tier {
        uint256 id;
        bool active;
        uint256 invocations;
        uint256 maxInvocations;
        uint256 price;
        uint256 maxMintPerTransaction;
        string name;
        string URI;
    }

    // Types of passes (populated by owner)
    mapping(uint256 => Tier) private _tiers;

    // Maps which token id corresponds to which pass tier
    mapping(uint256 => uint256) private _tokenTierMap;

    IGenHall private _genHallContract;

    // claim
    mapping(uint256 => bool) private _usedGenesisTokens;

    bool public _isGenesisClaimingAllowed = false;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function createTier(
        uint256 _id,
        uint256 _maxInvocations,
        uint256 _price,
        uint256 _maxMintPerTransaction,
        string memory _name,
        string memory _uri
    ) public onlyOwner {
        Tier memory _newTier = Tier(
            _id,
            false, // active
            0, // invocations
            _maxInvocations,
            _price,
            _maxMintPerTransaction,
            _name,
            _uri
        );

        _tiers[_id] = _newTier;
    }

    function adminMint(uint256 _id, uint256 _amount) public onlyOwner {
        // in case the user requests to mint more tokens than maxInvocations, we just adjust the amount to the
        // number of remaining tokens
        if (_tiers[_id].invocations + _amount > _tiers[_id].maxInvocations)
            _amount = _tiers[_id].maxInvocations - _tiers[_id].invocations;

        require(
            _tiers[_id].invocations < _tiers[_id].maxInvocations,
            "Max invocations reached for this pass."
        );

        for (uint256 i = 0; i < _amount; i++) {
            _tiers[_id].invocations++;

            uint256 tokenId = totalSupply() + 1;

            _tokenTierMap[tokenId] = _id;

            // Mint the corresponding token
            _safeMint(_msgSender(), tokenId);
        }
    }

    function purchase(uint256 _id, uint256 _amount) public payable {
        require(_tiers[_id].active, "This pass tier is not active");

        // in case the user requests to mint more tokens than maxInvocations, we just adjust the amount to the
        // number of remaining tokens
        if (_tiers[_id].invocations + _amount > _tiers[_id].maxInvocations)
            _amount = _tiers[_id].maxInvocations - _tiers[_id].invocations;

        require(
            _tiers[_id].invocations < _tiers[_id].maxInvocations,
            "Max invocations reached for this pass."
        );
        require(
            msg.value >= _tiers[_id].price * _amount,
            "Sent value is not enough to mint the amount of passes specified."
        );
        require(
            _amount <= _tiers[_id].maxMintPerTransaction,
            "You are trying to mint too many tokens in a single transaction."
        );

        for (uint256 i = 0; i < _amount; i++) {
            _tiers[_id].invocations++;

            uint256 tokenId = totalSupply() + 1;

            _tokenTierMap[tokenId] = _id;

            // Mint the corresponding token
            _safeMint(_msgSender(), tokenId);
        }

        // If the user has sent more ether than necessary for minting _amount tokens, we refund the excess Ether
        if (msg.value > (_tiers[_id].price * _amount)) {
            uint256 refundAmount = msg.value - (_tiers[_id].price * _amount);
            // refund
            payable(_msgSender()).transfer(refundAmount);
        }
    }

    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    // returns 2 arrays: first one are the genesis tokens owned by the address
    // second is an array filled with zeroes and ones 0 => used, 1 => usable (to get a pass)
    function getGenesisTokensByOwner(address _owner)
        public
        view
        returns (
            uint256[] memory ownedGenesisTokens,
            uint256[] memory ownedGenesisTokensStatus
        )
    {
        uint256[] memory _ownedTokens = _genHallContract
            .getTokensByOwner(_owner);
        uint256[] memory _ownedGenesisTokens = new uint256[](
            _ownedTokens.length
        );
        uint256[] memory _ownedGenesisTokensStatus = new uint256[](
            _ownedTokens.length
        );

        uint256 j = 0;
        for (uint256 i = 0; i < _ownedTokens.length; i++) {
            (, uint256 _collectionId, , ) = _genHallContract
                .getTokenInfo(_ownedTokens[i]);
            if (_collectionId == 1) {
                _ownedGenesisTokens[j] = _ownedTokens[i];
                if (_usedGenesisTokens[_ownedTokens[i]]) {
                    _ownedGenesisTokensStatus[j] = 0;
                } else {
                    _ownedGenesisTokensStatus[j] = 1;
                }
                j++;
            }
        }

        uint256[] memory _ownedGenesisTokensReturn = new uint256[](j);
        uint256[] memory _ownedGenesisTokensStatusReturn = new uint256[](j);

        for (uint256 k = 0; k < j; k++) {
            _ownedGenesisTokensReturn[k] = _ownedGenesisTokens[k];
            _ownedGenesisTokensStatusReturn[k] = _ownedGenesisTokensStatus[k];
        }

        return (_ownedGenesisTokensReturn, _ownedGenesisTokensStatusReturn);
    }

    function getPassInfo(uint256 _passId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            address owner
        )
    {
        uint256 _passTier = _tokenTierMap[_passId];
        return (
            _tiers[_passTier].id,
            _tiers[_passTier].name,
            ownerOf(_passId)
        );
    }

    function getTierInfo(uint256 _id)
        public
        view
        returns (
            uint256 id,
            bool active,
            uint256 invocations,
            uint256 maxInvocations,
            uint256 price,
            uint256 maxMintPerTransaction,
            string memory name
        )
    {
        return (
            _tiers[_id].id,
            _tiers[_id].active,
            _tiers[_id].invocations,
            _tiers[_id].maxInvocations,
            _tiers[_id].price,
            _tiers[_id].maxMintPerTransaction,
            _tiers[_id].name
        );
    }

    function getMembershipTier(uint256 _membershipId)
        public
        view
        returns (uint256)
    {
        return _tokenTierMap[_membershipId];
    }

    function isGenesisTokenUsed(uint256 _tokenId) public view returns (bool) {
        return _usedGenesisTokens[_tokenId];
    }

    // claim for base pass requires only one genesis token
    function claimBasePass(uint256[] memory _tokenIds) public payable {
        require(
            _isGenesisClaimingAllowed,
            "Claiming Pass through genesis collection is not allowed at this time."
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Get token info
            (
                ,
                uint256 _collectionId,
                address _owner,

            ) = _genHallContract.getTokenInfo(_tokenIds[i]);

            // check if genesis
            require(
                _collectionId == 1,
                "Only tokens from Genesis Collection can be used to claim Passes"
            );

            // check that sender owns the token
            require(
                _owner == _msgSender(),
                "Sender does not own the token being used to claim the the Pass"
            );

            // check if the token has already been used to claim a pass;
            require(
                !_usedGenesisTokens[_tokenIds[i]],
                "This token was already used to claim a Pass"
            );

            // Sets the token as used
            _usedGenesisTokens[_tokenIds[i]] = true;

            _tiers[1].invocations++;
            _tiers[1].maxInvocations++;

            uint256 tokenId = totalSupply() + 1;

            _tokenTierMap[tokenId] = 1;

            // Mint the corresponding token
            _safeMint(_msgSender(), tokenId);
        }
    }

    // claim for Collector pass requires 10 genesis token
    function claimCollectorPass(uint256[] memory tokenIds) public payable {
        require(
            _isGenesisClaimingAllowed,
            "Claiming Pass through genesis collection is not allowed at this time."
        );

        require(
            tokenIds.length == 10,
            "Wrong amount of tokens sent. Need 10 tokens for a Collector pass."
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // Get token info
            (
                ,
                uint256 _collectionId,
                address _owner,

            ) = _genHallContract.getTokenInfo(tokenIds[i]);

            // check if genesis
            require(
                _collectionId == 1,
                "Only tokens from Genesis Collection can be used to claim Passes"
            );

            // check that sender owns the token
            require(
                _owner == _msgSender(),
                "Sender does not own the token being used to claim the the Pass"
            );

            // check if the token has already been used to claim a pass;
            require(
                !_usedGenesisTokens[tokenIds[i]],
                "This token was already used to claim a Pass"
            );

            // Sets the token as used
            _usedGenesisTokens[tokenIds[i]] = true;
        }

        _tiers[2].invocations++;
        _tiers[2].maxInvocations++;

        uint256 tokenId = totalSupply() + 1;

        _tokenTierMap[tokenId] = 2;

        // Mint the corresponding token
        _safeMint(_msgSender(), tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(_msgSender()).transfer(balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        uint256 _id = _tokenTierMap[tokenId];

        return _tiers[_id].URI;
    }

    function setIsGenesisClaimingAllowed(bool _allowed) public onlyOwner {
        _isGenesisClaimingAllowed = _allowed;
    }

    function setGenHallContract(
        address _genHallContractAddress
    ) public onlyOwner {
        _genHallContract = IGenHall(
            _genHallContractAddress
        );
    }

    function setTierActive(uint256 _id, bool _active) public onlyOwner {
        _tiers[_id].active = _active;
    }

    function setTierMaxInvocations(uint256 _id, uint256 _maxInvocations)
        public
        onlyOwner
    {
        _tiers[_id].maxInvocations = _maxInvocations;
    }

    function setTierPrice(uint256 _id, uint256 _price) public onlyOwner {
        _tiers[_id].price = _price;
    }

    function setTierMaxMintPerTransaction(
        uint256 _id,
        uint256 _maxMintPerTransaction
    ) public onlyOwner {
        _tiers[_id].maxMintPerTransaction = _maxMintPerTransaction;
    }

    function setTierName(uint256 _id, string memory _name) public onlyOwner {
        _tiers[_id].name = _name;
    }

    function setTierURI(uint256 _id, string calldata URI) public onlyOwner {
        _tiers[_id].URI = URI;
    }

    function getTierURI(uint256 _id) public view returns (string memory URI) {
        return _tiers[_id].URI;
    }
}