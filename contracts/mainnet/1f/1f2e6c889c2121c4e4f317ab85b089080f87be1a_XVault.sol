// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Manageable.sol";

contract XVault is Manageable {
    event TokenMinted(uint256 tokenId, address indexed to);
    event TokensMinted(uint256[] tokenIds, address indexed to);
    event TokenBurned(uint256 tokenId, address indexed to);
    event TokensBurned(uint256[] tokenIds, address indexed to);

    constructor(address erc20Address, address cpmAddress) public {
        setERC20Address(erc20Address);
        setCpmAddress(cpmAddress);
    }

    function getCryptoPunkAtIndex(uint256 index) public view returns (uint256) {
        return getReserves().at(index);
    }

    function getReservesLength() public view returns (uint256) {
        return getReserves().length();
    }

    function isCryptoPunkDeposited(uint256 tokenId) public view returns (bool) {
        return getReserves().contains(tokenId);
    }

    function mintPunk(uint256 tokenId)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 fee = getFee(_msgSender(), 1, getMintFees());
        require(msg.value >= fee, "Value too low");
        _mintPunk(tokenId, false);
    }

    function _mintPunk(uint256 tokenId, bool partOfDualOp)
        private
        returns (bool)
    {
        address msgSender = _msgSender();

        require(tokenId < 10000, "tokenId too high");
        (bool forSale, uint256 _tokenId, address seller, uint256 minVal, address buyer) = getCPM()
            .punksOfferedForSale(tokenId);
        require(_tokenId == tokenId, "Wrong punk");
        require(forSale, "Punk not available");
        require(buyer == address(this), "Transfer not approved");
        require(minVal == 0, "Min value not zero");
        require(msgSender == seller, "Sender is not seller");
        require(
            msgSender == getCPM().punkIndexToAddress(tokenId),
            "Sender is not owner"
        );
        getCPM().buyPunk(tokenId);
        getReserves().add(tokenId);
        if (!partOfDualOp) {
            uint256 tokenAmount = 10**18;
            getERC20().mint(msgSender, tokenAmount);
        }
        emit TokenMinted(tokenId, _msgSender());
        return true;
    }

    function mintPunkMultiple(uint256[] memory tokenIds)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 fee = getFee(_msgSender(), tokenIds.length, getMintFees());
        require(msg.value >= fee, "Value too low");
        _mintPunkMultiple(tokenIds, false);
    }

    function _mintPunkMultiple(uint256[] memory tokenIds, bool partOfDualOp)
        private
        returns (uint256)
    {
        require(tokenIds.length > 0, "No tokens");
        require(tokenIds.length <= 100, "Over 100 tokens");
        uint256[] memory newTokenIds = new uint256[](tokenIds.length);
        uint256 numNewTokens = 0;
        address msgSender = _msgSender();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId < 10000, "tokenId too high");
            (bool forSale, uint256 _tokenId, address seller, uint256 minVal, address buyer) = getCPM()
                .punksOfferedForSale(tokenId);
            bool rightToken = _tokenId == tokenId;
            bool isApproved = buyer == address(this);
            bool priceIsZero = minVal == 0;
            bool isSeller = msgSender == seller;
            bool isOwner = msgSender == getCPM().punkIndexToAddress(tokenId);
            if (
                forSale &&
                rightToken &&
                isApproved &&
                priceIsZero &&
                isSeller &&
                isOwner
            ) {
                getCPM().buyPunk(tokenId);
                getReserves().add(tokenId);
                newTokenIds[numNewTokens] = tokenId;
                numNewTokens = numNewTokens.add(1);
            }
        }
        if (numNewTokens > 0) {
            if (!partOfDualOp) {
                uint256 tokenAmount = numNewTokens * (10**18);
                getERC20().mint(msgSender, tokenAmount);
            }
            emit TokensMinted(newTokenIds, msgSender);
        }
        return numNewTokens;
    }

    function redeemPunk() public payable nonReentrant whenNotPaused {
        uint256 fee = getFee(_msgSender(), 1, getBurnFees());
        require(msg.value >= fee, "Value too low");
        _redeemPunk(false);
    }

    function _redeemPunk(bool partOfDualOp) private {
        address msgSender = _msgSender();
        uint256 tokenAmount = 10**18;
        require(
            partOfDualOp || (getERC20().balanceOf(msgSender) >= tokenAmount),
            "ERC20 balance too small"
        );
        require(
            partOfDualOp ||
                (getERC20().allowance(msgSender, address(this)) >= tokenAmount),
            "ERC20 allowance too small"
        );
        uint256 reservesLength = getReserves().length();
        uint256 randomIndex = getPseudoRand(reservesLength);
        uint256 tokenId = getReserves().at(randomIndex);
        if (!partOfDualOp) {
            getERC20().burnFrom(msgSender, tokenAmount);
        }
        getReserves().remove(tokenId);
        getCPM().transferPunk(msgSender, tokenId);
        emit TokenBurned(tokenId, msgSender);
    }

    function redeemPunkMultiple(uint256 numTokens)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 fee = getFee(_msgSender(), numTokens, getBurnFees());
        require(msg.value >= fee, "Value too low");
        _redeemPunkMultiple(numTokens, false);
    }

    function _redeemPunkMultiple(uint256 numTokens, bool partOfDualOp) private {
        require(numTokens > 0, "No tokens");
        require(numTokens <= 100, "Over 100 tokens");
        address msgSender = _msgSender();
        uint256 tokenAmount = numTokens * (10**18);
        require(
            partOfDualOp || (getERC20().balanceOf(msgSender) >= tokenAmount),
            "ERC20 balance too small"
        );
        require(
            partOfDualOp ||
                (getERC20().allowance(msgSender, address(this)) >= tokenAmount),
            "ERC20 allowance too small"
        );
        if (!partOfDualOp) {
            getERC20().burnFrom(msgSender, tokenAmount);
        }
        uint256[] memory tokenIds = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 reservesLength = getReserves().length();
            uint256 randomIndex = getPseudoRand(reservesLength);
            uint256 tokenId = getReserves().at(randomIndex);
            tokenIds[i] = tokenId;
            getReserves().remove(tokenId);
            getCPM().transferPunk(msgSender, tokenId);
        }
        emit TokensBurned(tokenIds, msgSender);
    }

    function mintAndRedeem(uint256 tokenId)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 fee = getFee(_msgSender(), 1, getDualFees());
        require(msg.value >= fee, "Value too low");
        require(_mintPunk(tokenId, true), "Minting failed");
        _redeemPunk(true);
    }

    function mintAndRedeemMultiple(uint256[] memory tokenIds)
        public
        payable
        nonReentrant
        whenNotPaused
        whenNotInSafeMode
    {
        uint256 numTokens = tokenIds.length;
        require(numTokens > 0, "No tokens");
        require(numTokens <= 20, "Over 20 tokens");
        uint256 fee = getFee(_msgSender(), numTokens, getDualFees());
        require(msg.value >= fee, "Value too low");
        uint256 numTokensMinted = _mintPunkMultiple(tokenIds, true);
        if (numTokensMinted > 0) {
            _redeemPunkMultiple(numTokens, true);
        }
    }

    function mintRetroactively(uint256 tokenId, address to)
        public
        onlyOwner
        whenNotLockedS
    {
        require(
            getCPM().punkIndexToAddress(tokenId) == address(this),
            "Not owner"
        );
        require(!getReserves().contains(tokenId), "Already in reserves");
        uint256 cryptoPunkBalance = getCPM().balanceOf(address(this));
        require(
            (getERC20().totalSupply() / (10**18)) < cryptoPunkBalance,
            "No excess NFTs"
        );
        getReserves().add(tokenId);
        getERC20().mint(to, 10**18);
        emit TokenMinted(tokenId, _msgSender());
    }

    function redeemRetroactively(address to) public onlyOwner whenNotLockedS {
        require(
            getERC20().balanceOf(address(this)) >= (10**18),
            "Not enough PUNK"
        );
        getERC20().burn(10**18);
        uint256 reservesLength = getReserves().length();
        uint256 randomIndex = getPseudoRand(reservesLength);

        uint256 tokenId = getReserves().at(randomIndex);
        getReserves().remove(tokenId);
        getCPM().transferPunk(to, tokenId);
        emit TokenBurned(tokenId, _msgSender());
    }
}
