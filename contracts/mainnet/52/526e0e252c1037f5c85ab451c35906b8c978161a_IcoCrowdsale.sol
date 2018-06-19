pragma solidity 0.4.18;


/*
 * https://github.com/OpenZeppelin/zeppelin-solidity
 *
 * The MIT License (MIT)
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/*
 * https://github.com/OpenZeppelin/zeppelin-solidity
 *
 * The MIT License (MIT)
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/**
 * @title Token interface compatible with ICO Crowdsale
 * @author Jakub Stefanski (https://github.com/jstefanski)
 * @author Wojciech Harzowski (https://github.com/harzo)
 * @author Dominik Kroliczek (https://github.com/kruligh)
 *
 * https://github.com/OnLivePlatform/onlive-contracts
 *
 * The BSD 3-Clause Clear License
 * Copyright (c) 2018 OnLive LTD
 */
contract IcoToken {
    uint256 public decimals;

    function transfer(address to, uint256 amount) public;
    function mint(address to, uint256 amount) public;
    function burn(uint256 amount) public;

    function balanceOf(address who) public view returns (uint256);
}


/**
 * @title ICO Crowdsale with multiple price tiers and limited supply
 * @author Jakub Stefanski (https://github.com/jstefanski)
 * @author Wojciech Harzowski (https://github.com/harzo)
 * @author Dominik Kroliczek (https://github.com/kruligh)
 *
 * https://github.com/OnLivePlatform/onlive-contracts
 *
 * The BSD 3-Clause Clear License
 * Copyright (c) 2018 OnLive LTD
 */
contract IcoCrowdsale is Ownable {

    using SafeMath for uint256;

    /**
     * @dev Structure representing price tier
     */
    struct Tier {
        /**
        * @dev The first block of the tier (inclusive)
        */
        uint256 startBlock;
        /**
        * @dev Price of token in Wei
        */
        uint256 price;
    }

    /**
     * @dev Address of contribution wallet
     */
    address public wallet;

    /**
     * @dev Address of compatible token instance
     */
    IcoToken public token;

    /**
     * @dev Minimum ETH value sent as contribution
     */
    uint256 public minValue;

    /**
     * @dev Indicates whether contribution identified by bytes32 id is already registered
     */
    mapping (bytes32 => bool) public isContributionRegistered;

    /**
     * @dev Stores price tiers in chronological order
     */
    Tier[] private tiers;

    /**
    * @dev The last block of crowdsale (inclusive)
    */
    uint256 public endBlock;

    modifier onlySufficientValue(uint256 value) {
        require(value >= minValue);
        _;
    }

    modifier onlyUniqueContribution(bytes32 id) {
        require(!isContributionRegistered[id]);
        _;
    }

    modifier onlyActive() {
        require(isActive());
        _;
    }

    modifier onlyFinished() {
        require(isFinished());
        _;
    }

    modifier onlyScheduledTiers() {
        require(tiers.length > 0);
        _;
    }

    modifier onlyNotFinalized() {
        require(!isFinalized());
        _;
    }

    modifier onlySubsequentBlock(uint256 startBlock) {
        if (tiers.length > 0) {
            require(startBlock > tiers[tiers.length - 1].startBlock);
        }
        _;
    }

    modifier onlyNotZero(uint256 value) {
        require(value != 0);
        _;
    }

    modifier onlyValid(address addr) {
        require(addr != address(0));
        _;
    }

    function IcoCrowdsale(
        address _wallet,
        IcoToken _token,
        uint256 _minValue
    )
        public
        onlyValid(_wallet)
        onlyValid(_token)
    {
        wallet = _wallet;
        token = _token;
        minValue = _minValue;
    }

    /**
     * @dev Contribution is accepted
     * @param contributor address The recipient of the tokens
     * @param value uint256 The amount of contributed ETH
     * @param amount uint256 The amount of tokens
     */
    event ContributionAccepted(address indexed contributor, uint256 value, uint256 amount);

    /**
     * @dev Off-chain contribution registered
     * @param id bytes32 A unique contribution id
     * @param contributor address The recipient of the tokens
     * @param amount uint256 The amount of tokens
     */
    event ContributionRegistered(bytes32 indexed id, address indexed contributor, uint256 amount);

    /**
     * @dev Tier scheduled with given start block and price
     * @param startBlock uint256 The first block of tier activation (inclusive)
     * @param price uint256 The price active during tier
     */
    event TierScheduled(uint256 startBlock, uint256 price);

    /**
     * @dev Crowdsale end block scheduled
     * @param availableAmount uint256 The amount of tokens available in crowdsale
     * @param endBlock uint256 The last block of crowdsale (inclusive)
     */
    event Finalized(uint256 endBlock, uint256 availableAmount);

    /**
     * @dev Unsold tokens burned
     */
    event RemainsBurned(uint256 burnedAmount);

    /**
     * @dev Accept ETH transfers as contributions
     */
    function () public payable {
        acceptContribution(msg.sender, msg.value);
    }

    /**
     * @dev Contribute ETH in exchange for tokens
     * @param contributor address The address that receives tokens
     * @return uint256 Amount of received ONL tokens
     */
    function contribute(address contributor) public payable returns (uint256) {
        return acceptContribution(contributor, msg.value);
    }

    /**
     * @dev Register contribution with given id
     * @param id bytes32 A unique contribution id
     * @param contributor address The recipient of the tokens
     * @param amount uint256 The amount of tokens
     */
    function registerContribution(bytes32 id, address contributor, uint256 amount)
        public
        onlyOwner
        onlyActive
        onlyValid(contributor)
        onlyNotZero(amount)
        onlyUniqueContribution(id)
    {
        isContributionRegistered[id] = true;

        token.transfer(contributor, amount);

        ContributionRegistered(id, contributor, amount);
    }

    /**
     * @dev Schedule price tier
     * @param _startBlock uint256 Block when the tier activates, inclusive
     * @param _price uint256 The price of the tier
     */
    function scheduleTier(uint256 _startBlock, uint256 _price)
        public
        onlyOwner
        onlyNotFinalized
        onlySubsequentBlock(_startBlock)
        onlyNotZero(_startBlock)
        onlyNotZero(_price)
    {
        tiers.push(
            Tier({
                startBlock: _startBlock,
                price: _price
            })
        );

        TierScheduled(_startBlock, _price);
    }

    /**
     * @dev Schedule crowdsale end
     * @param _endBlock uint256 The last block end of crowdsale (inclusive)
     * @param _availableAmount uint256 Amount of tokens available in crowdsale
     */
    function finalize(uint256 _endBlock, uint256 _availableAmount)
        public
        onlyOwner
        onlyNotFinalized
        onlyScheduledTiers
        onlySubsequentBlock(_endBlock)
        onlyNotZero(_availableAmount)
    {
        endBlock = _endBlock;

        token.mint(this, _availableAmount);

        Finalized(_endBlock, _availableAmount);
    }

    /**
     * @dev Burns all tokens which have not been sold
     */
    function burnRemains()
        public
        onlyOwner
        onlyFinished
    {
        uint256 amount = availableAmount();

        token.burn(amount);

        RemainsBurned(amount);
    }

    /**
     * @dev Calculate amount of ONL tokens received for given ETH value
     * @param value uint256 Contribution value in wei
     * @return uint256 Amount of received ONL tokens if contract active, otherwise 0
     */
    function calculateContribution(uint256 value) public view returns (uint256) {
        uint256 price = currentPrice();
        if (price > 0) {
            return value.mul(10 ** token.decimals()).div(price);
        }

        return 0;
    }

    /**
     * @dev Find closest tier id to given block
     * @return uint256 Tier containing the block or zero if before start or last if after finished
     */
    function getTierId(uint256 blockNumber) public view returns (uint256) {
        for (uint256 i = tiers.length - 1; i >= 0; i--) {
            if (blockNumber >= tiers[i].startBlock) {
                return i;
            }
        }

        return 0;
    }

    /**
     * @dev Get price of the current tier
     * @return uint256 Current price if tiers defined, otherwise 0
     */
    function currentPrice() public view returns (uint256) {
        if (tiers.length > 0) {
            uint256 id = getTierId(block.number);
            return tiers[id].price;
        }

        return 0;
    }

    /**
     * @dev Get current tier id
     * @return uint256 Tier containing the block or zero if before start or last if after finished
     */
    function currentTierId() public view returns (uint256) {
        return getTierId(block.number);
    }

    /**
     * @dev Get available amount of tokens
     * @return uint256 Amount of unsold tokens
     */
    function availableAmount() public view returns (uint256) {
        return token.balanceOf(this);
    }

    /**
     * @dev Get specification of all tiers
     */
    function listTiers()
        public
        view
        returns (uint256[] startBlocks, uint256[] endBlocks, uint256[] prices)
    {
        startBlocks = new uint256[](tiers.length);
        endBlocks = new uint256[](tiers.length);
        prices = new uint256[](tiers.length);

        for (uint256 i = 0; i < tiers.length; i++) {
            startBlocks[i] = tiers[i].startBlock;
            prices[i] = tiers[i].price;

            if (i + 1 < tiers.length) {
                endBlocks[i] = tiers[i + 1].startBlock - 1;
            } else {
                endBlocks[i] = endBlock;
            }
        }
    }

    /**
     * @dev Check whether crowdsale is currently active
     * @return boolean True if current block number is within tier ranges, otherwise False
     */
    function isActive() public view returns (bool) {
        return
            tiers.length > 0 &&
            block.number >= tiers[0].startBlock &&
            block.number <= endBlock;
    }

    /**
     * @dev Check whether sale end is scheduled
     * @return boolean True if end block is defined, otherwise False
     */
    function isFinalized() public view returns (bool) {
        return endBlock > 0;
    }

    /**
     * @dev Check whether crowdsale has finished
     * @return boolean True if end block passed, otherwise False
     */
    function isFinished() public view returns (bool) {
        return endBlock > 0 && block.number > endBlock;
    }

    function acceptContribution(address contributor, uint256 value)
        private
        onlyActive
        onlyValid(contributor)
        onlySufficientValue(value)
        returns (uint256)
    {
        uint256 amount = calculateContribution(value);
        token.transfer(contributor, amount);

        wallet.transfer(value);

        ContributionAccepted(contributor, value, amount);

        return amount;
    }
}