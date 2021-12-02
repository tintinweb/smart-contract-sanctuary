// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./ExtendedAccessControl.sol";
import "./IEterToken.sol";
import "./IPresale.sol";

contract PrivateSell is ExtendedAccessControl {
    IEterToken private token;
    IPresale private presale;
    uint256 public PRESALE_START_TIMESTAMP = 0;
    uint256 public PRESALE_END_TIMESTAMP = 0;

    modifier presaleFinished() {
        require(block.timestamp >= PRESALE_END_TIMESTAMP);
        _;
    }

    modifier presaleInProgress() {
        require(
            block.timestamp >= PRESALE_START_TIMESTAMP &&
                block.timestamp <= PRESALE_END_TIMESTAMP
        );
        _;
    }
    uint256 public tokensSold = 0;
    modifier addressIsInWhitelistOrExceedBuyTime(
        address _address,
        uint256 _amount
    ) {
        uint256 whitelisted = whitelistedAmount(_address);
        require(
            ((PRESALE_START_TIMESTAMP + 12 hours + 10 minutes <=
                block.timestamp ||
                (PRESALE_START_TIMESTAMP + 12 hours <= block.timestamp &&
                    whitelisted > 0)) &&
                _amount + _tokenBuyed[_address] <=
                (1000 ether + whitelisted)) ||
                whitelisted >= _amount + _tokenBuyed[_address]
        );
        _;
    }

    constructor(
        address tokenAddress,
        address ceo,
        address coo,
        address cfo,
        address inv1,
        address inv2,
        uint256 presaleStart,
        uint256 presaleEnd,
        address presaleAddress
    ) ExtendedAccessControl(4) {
        token = IEterToken(tokenAddress);
        presale = IPresale(presaleAddress);
        PRESALE_START_TIMESTAMP = presaleStart;
        PRESALE_END_TIMESTAMP = presaleEnd;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, ceo);
        _setupRole(DEFAULT_ADMIN_ROLE, coo);
        _setupRole(DEFAULT_ADMIN_ROLE, cfo);
        _setupRole(DEFAULT_ADMIN_ROLE, inv1);
        _setupRole(DEFAULT_ADMIN_ROLE, inv2);
    }

    uint256 amountOfWhitelistedTokens = 0;
    uint256 public constant AMOUNT_OF_TOKENS_IN_SALE = 1200000 ether;
    uint256 public constant TOTAL_VESTING_TIME = 30 days * 9;
    uint256 public constant SELL_INTERVAL = 10000000000000000;
    uint256 public constant INTERVAL_BNB_PRICE = 1798502338053;

    mapping(address => uint8) private _withdrawalVotes;
    mapping(address => mapping(address => bool)) _alreadyVoteRecord;

    mapping(address => uint256) private _tokenBuyed;
    mapping(address => uint256) private _releasedTokens;
    mapping(address => uint256) private _whitelist;

    event newWhitelisted(address, uint256);
    event tokensReleased(address, uint256);
    event tokensBuyed(address, uint256);

    function userParticipatedInPrivateSell(address _address)
        private
        view
        returns (bool)
    {
        for (uint8 index = 0; index <= 16; index += 2) {
            uint256 count = presale.getOwnerkit(index, _address);
            if (count > 0) {
                return true;
            }
        }
        return false;
    }

    function remainingTokensInWhitelist(address _address)
        external
        view
        returns (uint256)
    {
        if (block.timestamp > PRESALE_END_TIMESTAMP) {
            return 0;
        }

        if (
            block.timestamp >= PRESALE_START_TIMESTAMP &&
            block.timestamp <= PRESALE_START_TIMESTAMP + 12 hours
        ) {
            return whitelistedAmount(_address) - _tokenBuyed[_address];
        }

        return 1000 ether + whitelistedAmount(_address) - _tokenBuyed[_address];
    }

    function addMembersToWhitelist(
        address[] memory membersAddress,
        uint256[] memory membersAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool isOnlyOne = membersAmount.length == 1;
        require(
            isOnlyOne || membersAddress.length == membersAmount.length,
            "Amount and members length can't be different"
        );

        for (uint256 i = 0; i < membersAddress.length; i++) {
            uint256 index = isOnlyOne ? 0 : i;

            require(
                amountOfWhitelistedTokens + membersAmount[index] <=
                    AMOUNT_OF_TOKENS_IN_SALE,
                "amount exceed total tokens in sale"
            );

            amountOfWhitelistedTokens += membersAmount[index];
            _whitelist[membersAddress[i]] += membersAmount[index];

            emit newWhitelisted(
                membersAddress[i],
                whitelistedAmount(membersAddress[i])
            );
        }
    }

    function modifyMemberWhitelist(address memberaddress, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            amountOfWhitelistedTokens - _whitelist[memberaddress] + amount <=
                AMOUNT_OF_TOKENS_IN_SALE,
            "amount exceed total tokens in sale"
        );

        amountOfWhitelistedTokens = amount - _whitelist[memberaddress];

        _whitelist[memberaddress] = amount;

        emit newWhitelisted(memberaddress, amount);
    }

    function whitelistedAmount(address _address) public view returns (uint256) {
        uint256 baseAmount = _whitelist[_address];
        if (userParticipatedInPrivateSell(_address)) {
            baseAmount += 100 ether;
        }
        return baseAmount;
    }

    function buyTokens(uint256 _amount)
        external
        payable
        presaleInProgress
        addressIsInWhitelistOrExceedBuyTime(msg.sender, _amount)
    {
        require(
            _amount % SELL_INTERVAL == 0,
            "the amount needs to increment with every 10000000000000000"
        );

        uint256 requiredAmount = (_amount / SELL_INTERVAL) * INTERVAL_BNB_PRICE;
        require(
            msg.value >= requiredAmount,
            "you need to send correct amount of tokens"
        );
        require(
            tokensSold + _amount <= AMOUNT_OF_TOKENS_IN_SALE,
            "not enought tokens remaining"
        );

        _releasedTokens[msg.sender] += _amount / 10;

        _tokenBuyed[msg.sender] += _amount;

        tokensSold += _amount;

        require(
            token.transfer(msg.sender, _amount / 10),
            "token transfer failed"
        );

        emit tokensBuyed(msg.sender, _tokenBuyed[msg.sender]);
    }

    function released(address _address) public view returns (uint256) {
        return _releasedTokens[_address];
    }

    function availableForRelease(address _address)
        public
        view
        returns (uint256)
    {
        return vestedAmount(_address) - released(_address);
    }

    function vestedAmount(address _address) public view returns (uint256) {
        if (block.timestamp < PRESALE_START_TIMESTAMP) {
            return 0;
        } else if (
            block.timestamp >= PRESALE_START_TIMESTAMP + TOTAL_VESTING_TIME
        ) {
            return _tokenBuyed[_address];
        } else {
            return
                ((_tokenBuyed[_address] - _tokenBuyed[_address] / 10) *
                    (block.timestamp - PRESALE_START_TIMESTAMP)) /
                TOTAL_VESTING_TIME +
                _tokenBuyed[_address] /
                10;
        }
    }

    function releaseTokens(uint256 _amount) external {
        require(
            availableForRelease(msg.sender) >= _amount,
            "can't release that tokens yet"
        );

        _releasedTokens[msg.sender] += _amount;

        require(token.transfer(msg.sender, _amount), "token transfer failed");

        emit tokensReleased(msg.sender, _amount);
    }

    function withdrawTokens(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _alreadyVoteRecord[_address][msg.sender] == false,
            "already voted"
        );
        require(_address != address(0), "can't burn");

        _alreadyVoteRecord[_address][msg.sender] = true;
        _withdrawalVotes[_address]++;

        if (_withdrawalVotes[_address] >= 4) {
            payable(_address).transfer(address(this).balance);
        }
    }

    function remainingTokens() public view returns (uint256) {
        return token.balanceOf(address(this)) - tokensSold;
    }
    
    function whitlistBuyed(address _address) external view returns(uint256){
		return _tokenBuyed[_address];
	}

    function sendRemainingTokens(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        presaleFinished
    {
        uint256 remaining = remainingTokens();
        require(_address != address(0), "can't hard burn");
        require(remaining > 0, "no tokens to send");
        require(token.transfer(_address, remaining), "token transfer failed");
    }
}