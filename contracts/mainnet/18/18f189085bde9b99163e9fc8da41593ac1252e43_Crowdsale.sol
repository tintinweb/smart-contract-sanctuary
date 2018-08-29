pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMathLibrary {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Integer module of two numbers, truncating the quotient.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    bool public paused = false;

    event Pause();

    event Unpause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract Operator is Ownable {
    mapping(address => bool) public operators;

    event OperatorAddressAdded(address addr);
    event OperatorAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that&#39;s not operator.
     */
    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    /**
     * @dev add an address to the operators
     * @param addr address
     * @return true if the address was added to the operators, false if the address was already in the operators
     */
    function addAddressToOperators(address addr) onlyOwner public returns(bool success) {
        if (!operators[addr]) {
            operators[addr] = true;
            emit OperatorAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the operators
     * @param addrs addresses
     * @return true if at least one address was added to the operators,
     * false if all addresses were already in the operators
     */
    function addAddressesToOperators(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToOperators(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the operators
     * @param addr address
     * @return true if the address was removed from the operators,
     * false if the address wasn&#39;t in the operators in the first place
     */
    function removeAddressFromOperators(address addr) onlyOwner public returns(bool success) {
        if (operators[addr]) {
            operators[addr] = false;
            emit OperatorAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the operators
     * @param addrs addresses
     * @return true if at least one address was removed from the operators,
     * false if all addresses weren&#39;t in the operators in the first place
     */
    function removeAddressesFromOperators(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromOperators(addrs[i])) {
                success = true;
            }
        }
    }
}

contract Whitelist is Operator {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that&#39;s not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOperator public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] addrs) onlyOperator public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn&#39;t in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOperator public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren&#39;t in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] addrs) onlyOperator public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}

interface Token {
    function transferFrom(address from, address to, uint amount) external returns(bool);
}

contract Crowdsale is Pausable, Whitelist {
    using SafeMathLibrary for uint;

    address private EMPTY_ADDRESS = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    Token public token;

    address public beneficiary;
    address public pool;
    
    uint internal decimals = 10 ** 18;

    struct Funding {
        address[] buyers;
        address[] winners;
        uint32 exchangeRatio;
        uint8 minAccepting;
        uint8 maxAccepting;
        uint8 maxLotteryNumber;
    }

    struct BuyerStage {
        uint8 funded;
        bool lotteryBonusWon;
        bool ultimateBonusWon;
        bool bonusReleased;
    }

    struct Bonus {
        uint32 buying;
        uint32 lottery;
        uint32 ultimate;
    }

    struct Stage {
        Bonus bonus;
        address[] buyers;
        address[] winners;
        address ultimateBonusWinner;
        uint32 openingTime;
        uint16 fundGoal;
        uint16 fundRaised;
        uint16 nextLotteryRaised;
    }

    Funding private funding;

    mapping(address => mapping(uint8 => BuyerStage)) private buyers;

    mapping(uint8 => Stage) private stages;

    event BuyerFunded(address indexed buyer, uint8 stageIndex, uint8 amount);
    event BuyerLotteryBonusWon(address indexed buyer, uint8 stageIndex, uint8 lotteryNumber, uint16 fundRaised);
    event BuyerUltimateBonusWon(address indexed buyer, uint8 stageIndex);
    event StageOpeningTimeSet(uint8 index);
    event StageGoalReached(uint8 index);
    event FinalGoalReached();

    constructor (
        address _tokenContractAddress,
        address _beneficiary,
        address _pool
    ) public {
        token = Token(_tokenContractAddress);
        beneficiary = _beneficiary;
        pool = _pool;

        funding.exchangeRatio = 75000;
        funding.minAccepting = 1;
        funding.maxAccepting = 10;
        funding.maxLotteryNumber = 9;

        stages[1].openingTime = 1535500800;
        stages[1].fundGoal = 3000;
        stages[1].bonus.buying = 3600000; // 80%
        stages[1].bonus.lottery = 450000; // 10%
        stages[1].bonus.ultimate = 450000; // 10%

        stages[2].fundGoal = 3000;
        stages[2].bonus.buying = 2250000; // 50%
        stages[2].bonus.lottery = 1125000; // 25%
        stages[2].bonus.ultimate = 1125000; // 25%

        stages[3].fundGoal = 3000;
        stages[3].bonus.buying = 1350000; // 30%
        stages[3].bonus.lottery = 1575000; // 35%
        stages[3].bonus.ultimate = 1575000; // 35%

        stages[4].fundGoal = 3000;
        stages[4].bonus.buying = 0; // 0%
        stages[4].bonus.lottery = 2250000; // 50%
        stages[4].bonus.ultimate = 2250000; // 50%

        for (uint8 i = 1; i <= 4; i++) {
            stages[i].ultimateBonusWinner = EMPTY_ADDRESS;
        }
    }
    
    function getStageAverageBonus(uint8 _index) public view returns(
        uint32 buying,
        uint32 lottery,
        uint32 ultimate
    ) {
        Stage storage stage = stages[_index];
        buying = stage.bonus.buying > 0 ? stage.bonus.buying / stage.fundGoal : 0;
        if (stageFundGoalReached(_index) == true) {
            lottery = stage.bonus.lottery / uint16(stage.winners.length);
            ultimate = stage.bonus.ultimate + (stage.bonus.lottery - lottery * uint16(stage.winners.length));
        }
    } 

    function getOpenedStageIndex() public view returns(uint8) {
        for (uint8 i = 1; i <= 4; i++) {
            if (stages[i].openingTime > 0 && now >= stages[i].openingTime && stages[i].fundRaised < stages[i].fundGoal) {
                return i;
            }
        }
        return 0;
    }

    function getRandomNumber(uint256 power) private view returns (uint256) {
        uint256 ddb = uint256(blockhash(block.number - 1));
        uint256 r = uint256(keccak256(abi.encodePacked(ddb - 1)));
        while (r == 0) {
            ddb += 256;
            r = uint256(keccak256(abi.encodePacked(ddb - 1)));
        }
        return uint256(keccak256(abi.encodePacked(r, block.difficulty, now))) % power;
    }

    function getTodayLotteryNumber() public view returns(uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(uint16(now / 1 days)))) % funding.maxLotteryNumber);
    }

    function getSummary() public view returns(
        uint32 exchangeRatio,
        uint16 fundGoal,
        uint32 bonus,
        uint16 fundRaised,
        uint16 buyersCount,
        uint16 winnersCount,
        uint8 minAccepting,
        uint8 maxAccepting,
        uint8 openedStageIndex,
        uint8 todayLotteryNumber
    ) {
        for (uint8 i = 1; i <= 4; i++) {
            fundGoal += stages[i].fundGoal;
            fundRaised += stages[i].fundRaised;
            bonus += stages[i].bonus.buying + stages[i].bonus.lottery + stages[i].bonus.ultimate;
        }

        exchangeRatio = funding.exchangeRatio;
        minAccepting = funding.minAccepting;
        maxAccepting = funding.maxAccepting;
        buyersCount = uint16(funding.buyers.length);
        winnersCount = uint16(funding.winners.length);
        openedStageIndex = getOpenedStageIndex();
        todayLotteryNumber = getTodayLotteryNumber();
    }

    function setStageOpeningTime(uint8 _index, uint32 _openingTime) public onlyOwner whenNotPaused returns(bool) {
        if (stages[_index].openingTime > 0) {
            require(stages[_index].openingTime > now, "Stage has been already opened.");
        }
        stages[_index].openingTime = _openingTime;
        emit StageOpeningTimeSet(_index);
        return true;
    }

    function getStages() public view returns(
        uint8[4] index,
        uint32[4] openingTime,
        uint32[4] buyingBonus,
        uint32[4] lotteryBonus,
        uint32[4] ultimateBonus,
        uint16[4] fundGoal,
        uint16[4] fundRaised,
        uint16[4] buyersCount,
        uint16[4] winnersCount,
        address[4] ultimateBonusWinner
    ) {
        for (uint8 i = 1; i <= 4; i++) {
            uint8 _i = i - 1;
            index[_i] = i;
            openingTime[_i] = stages[i].openingTime;
            buyingBonus[_i] = stages[i].bonus.buying;
            lotteryBonus[_i] = stages[i].bonus.lottery;
            ultimateBonus[_i] = stages[i].bonus.ultimate;
            fundGoal[_i] = stages[i].fundGoal;
            fundRaised[_i] = stages[i].fundRaised;
            buyersCount[_i] = uint16(stages[i].buyers.length);
            winnersCount[_i] = uint16(stages[i].winners.length);
            ultimateBonusWinner[_i] = stages[i].ultimateBonusWinner == EMPTY_ADDRESS ? address(0) : stages[i].ultimateBonusWinner;
        }
    }

    function getBuyers(uint16 _offset, uint8 _limit) public view returns(
        uint16 total,
        uint16 start,
        uint16 end,
        uint8 count,
        address[] items
    ) {
        total = uint16(funding.buyers.length);
        if (total > 0) {
            start = _offset > total - 1 ? total - 1 : _offset;
            end = (start + _limit > total) ? total - 1 : (start + _limit > 0 ? start + _limit - 1 : 0);
            count = uint8(end - start + 1);
        }

        if (count > 0) {
            address[] memory _items = new address[](count);
            uint8 j = 0;
            for (uint16 i = start; i <= end; i++) {
                _items[j] = funding.buyers[i];
                j++;
            }
            items = _items;
        }
    }

    function getWinners(uint16 _offset, uint8 _limit) public view returns(
        uint16 total,
        uint16 start,
        uint16 end,
        uint8 count,
        address[] items
    ) {
        total = uint16(funding.winners.length);
        if (total > 0) {
            start = _offset > total - 1 ? total - 1 : _offset;
            end = (start + _limit > total) ? total - 1 : (start + _limit > 0 ? start + _limit - 1 : 0);
            count = uint8(end - start + 1);
        }

        if (count > 0) {
            address[] memory _items = new address[](count);
            uint8 j = 0;
            for (uint16 i = start; i <= end; i++) {
                _items[j] = funding.winners[i];
                j++;
            }
            items = _items;
        }
    }

    function getStageBuyers(uint8 _index, uint16 _offset, uint8 _limit) public view returns(
        uint16 total,
        uint16 start,
        uint16 end,
        uint8 count,
        address[] items
    ) {
        Stage storage stage = stages[_index];

        total = uint16(stage.buyers.length);
        if (total > 0) {
            start = _offset > total - 1 ? total - 1 : _offset;
            end = (start + _limit > total) ? total - 1 : (start + _limit > 0 ? start + _limit - 1 : 0);
            count = uint8(end - start + 1);
        }

        if (count > 0) {
            address[] memory _items = new address[](count);
            uint8 j = 0;
            for (uint16 i = start; i <= end; i++) {
                _items[j] = stage.buyers[i];
                j++;
            }
            items = _items;
        }
    }

    function getStageWinners(uint8 _index, uint16 _offset, uint8 _limit) public view returns(
        uint16 total,
        uint16 start,
        uint16 end,
        uint8 count,
        address[] items
    ) {
        Stage storage stage = stages[_index];

        total = uint16(stage.winners.length);
        if (total > 0) {
            start = _offset > total - 1 ? total - 1 : _offset;
            end = (start + _limit > total) ? total - 1 : (start + _limit > 0 ? start + _limit - 1 : 0);
            count = uint8(end - start + 1);
        }

        if (count > 0) {
            address[] memory _items = new address[](count);
            uint8 j = 0;
            for (uint16 i = start; i <= end; i++) {
                _items[j] = stage.winners[i];
                j++;
            }
            items = _items;
        }
    }

    function getBuyer(address _buyer) public view returns(
        uint8[4] funded,
        uint32[4] buyingBonus,
        uint32[4] lotteryBonus,
        uint32[4] ultimateBonus,
        bool[4] lotteryBonusWon,
        bool[4] ultimateBonusWon,
        bool[4] bonusReleasable,
        bool[4] bonusReleased
    ) {
        for (uint8 i = 1; i <= 4; i++) {
            BuyerStage storage buyerStage = buyers[_buyer][i];
            funded[i - 1] = buyerStage.funded;
            lotteryBonusWon[i - 1] = buyerStage.lotteryBonusWon;
            ultimateBonusWon[i - 1] = buyerStage.ultimateBonusWon;
            bonusReleasable[i - 1] = stageFundGoalReached(i);
            bonusReleased[i - 1] = buyerStage.bonusReleased;

            uint32 _buyingBonus;
            uint32 _lotteryBonus;
            uint32 _ultimateBonus;

            (_buyingBonus, _lotteryBonus, _ultimateBonus) = getStageAverageBonus(i);
            
            buyingBonus[i - 1] = buyerStage.funded * _buyingBonus;

            if (buyerStage.lotteryBonusWon == true) {
                lotteryBonus[i - 1] = _lotteryBonus;
            }
            
            if (buyerStage.ultimateBonusWon == true) {
                ultimateBonus[i - 1] = _ultimateBonus;
            }
        }
    }

    function finalFundGoalReached() public view returns(bool) {
        for (uint8 i = 1; i <= 4; i++) {
            if (stageFundGoalReached(i) == false) {
                return false;
            }
        }
        return true;
    }

    function stageFundGoalReached(uint8 _index) public view returns(bool) {
        Stage storage stage = stages[_index];
        return (stage.openingTime > 0 && stage.openingTime <= now && stage.fundRaised >= stage.fundGoal);
    }

    function tokenFallback(address _from, uint256 _value) public returns(bool) {
        require(msg.sender == address(token));
        return true;
    }

    function releasableViewOrSend(address _buyer, bool _send) private returns(uint32) {
        uint32 bonus;
        for (uint8 i = 1; i <= 4; i++) {
            BuyerStage storage buyerStage = buyers[_buyer][i];

            if (stageFundGoalReached(i) == false || buyerStage.bonusReleased == true) {
                continue;
            }
            
            uint32 buyingBonus;
            uint32 lotteryBonus;
            uint32 ultimateBonus;

            (buyingBonus, lotteryBonus, ultimateBonus) = getStageAverageBonus(i);

            bonus += buyerStage.funded * buyingBonus;
            if (buyerStage.lotteryBonusWon == true) {
                bonus += lotteryBonus;
            }
            if (buyerStage.ultimateBonusWon == true) {
                bonus += ultimateBonus;
            }
            
            if (_send == true) {
                buyerStage.bonusReleased = true;
            }
        }
        
        if (_send == true) {
            require(bonus > 0, "No bonus.");
            token.transferFrom(pool, _buyer, uint256(bonus).mul(decimals));
        }
        
        return bonus;
    }

    function releasable(address _buyer) public view returns(uint32) {
        return releasableViewOrSend(_buyer, false);
    }

    function release(address _buyer) private {
        releasableViewOrSend(_buyer, true);
    }

    function getBuyerFunded(address _buyer) private view returns(uint8) {
        uint8 funded;
        for (uint8 i = 1; i <= 4; i++) {
            funded += buyers[_buyer][i].funded;
        }
        return funded;
    }

    function hasBuyerLotteryBonusWon(address _buyer) private view returns(bool) {
        for (uint8 i = 1; i <= 4; i++) {
            if (buyers[_buyer][i].lotteryBonusWon) {
                return true;
            }
        }
        return false;
    }

    function buy(address _buyer, uint256 value) private {
        uint8 i = getOpenedStageIndex();
        require(i > 0, "No opening stage found.");
        require(value >= 1 ether, "The amount too low.");

        Stage storage stage = stages[i];

        uint16 remain;
        uint16 funded = getBuyerFunded(_buyer);
        uint256 amount = value.div(1 ether);
        uint256 refund = value.sub(amount.mul(1 ether));

        remain = funding.maxAccepting - funded;
        require(remain > 0, "Total amount too high.");
        if (remain < amount) {
            refund = refund.add(amount.sub(uint256(remain)).mul(1 ether));
            amount = remain;
        }

        remain = stage.fundGoal - stage.fundRaised;
        require(remain > 0, "Stage funding goal reached.");
        if (remain < amount) {
            refund = refund.add(amount.sub(uint256(remain)).mul(1 ether));
            amount = remain;
        }

        if (refund > 0) {
            require(_buyer.send(refund), "Refund failed.");
        }

        BuyerStage storage buyerStage = buyers[_buyer][i];

        if (funded == 0) {
            funding.buyers.push(_buyer);
        }
        if (buyerStage.funded == 0) {
            stage.buyers.push(_buyer);
        }
        buyerStage.funded += uint8(amount);

        stage.fundRaised += uint16(amount);

        emit BuyerFunded(_buyer, i, uint8(amount));

        uint8 todayLotteryNumber = getTodayLotteryNumber();

        if (stage.nextLotteryRaised == 0) {
            stage.nextLotteryRaised = todayLotteryNumber;
        }
        
        uint8 mod;
        if (stage.fundRaised > 10) {
            mod = uint8(stage.fundRaised % 10);
            if (mod == 0) {
                mod = 10;
            }
        } else {
            mod = uint8(stage.fundRaised);
        }
        if (mod >= todayLotteryNumber && stage.fundRaised >= stage.nextLotteryRaised) {
            if (hasBuyerLotteryBonusWon(_buyer) == false) {
                funding.winners.push(_buyer);
            }
            if (buyerStage.lotteryBonusWon == false) {
                buyerStage.lotteryBonusWon = true;
                stage.winners.push(_buyer);
                emit BuyerLotteryBonusWon(_buyer, i, todayLotteryNumber, stage.fundRaised);
            }
            stage.nextLotteryRaised += 10;
        }

        if (stage.fundGoal == stage.fundRaised) {
            stage.ultimateBonusWinner = stage.winners[uint16(getRandomNumber(stage.winners.length - 1))];
            buyers[stage.ultimateBonusWinner][i].ultimateBonusWon = true;

            emit StageGoalReached(i);
            emit BuyerUltimateBonusWon(_buyer, i);
        }

        if (finalFundGoalReached() == true) {
            emit FinalGoalReached();
        }

        uint256 tokens = amount * funding.exchangeRatio;
        require(beneficiary.send(amount.mul(1 ether)), "Send failed.");
        require(token.transferFrom(pool, _buyer, tokens.mul(decimals)), "Deliver failed.");
    }

    function () whenNotPaused onlyWhitelisted public payable {
        require(beneficiary != msg.sender, "The beneficiary cannot buy CATT.");
        if (msg.value == 0) {
            release(msg.sender);
        } else {
            buy(msg.sender, msg.value);
        }
    }
}