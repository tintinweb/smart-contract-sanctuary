/**
 *Submitted for verification at Etherscan.io on 2020-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256 c) {
        require(b <= a, errorMessage);
        c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256 c) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    uint256 totalSupply_;

    mapping(address => uint256) balances;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    /**
     * @dev Transfer token for a specified address
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "transfer addr is the zero address");
        require(_value <= balances[_from], "lack of balance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override
        returns (bool)
    {
        require(_to != address(0), "transfer addr is the zero address");
        require(_value <= balances[_from], "lack of balance");
        require(_value <= allowed[_from][msg.sender], "lack of transfer balance allowed");
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        // avoid race condition
        require((_value == 0) || (allowed[msg.sender][_spender] == 0), "reset allowance to 0 before change it's value.");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        override
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}


contract Token_StandardToken is StandardToken {
    // region{fields}
    string public name;
    string public symbol;
    uint8 public decimals;

    // region{Constructor}
    // note : [(final)totalSupply] >> claimAmount * 10 ** decimals
    // example : args << "The Kh Token No.X", "ABC", "10000000000", "18"
    constructor(
        string memory _token_name,
        string memory _symbol,
        uint256 _claim_amount,
        uint8 _decimals,
        address minaddr
    ) public {
        name = _token_name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _claim_amount.mul(10 ** uint256(decimals));
        balances[minaddr] = totalSupply_;
        emit Transfer(address(0), minaddr, totalSupply_);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 * USDT transfer and transferFrom not returns
 */
interface ITokenERC20_USDT {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface ITokenERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @title DB
 * @dev This Provide database support services
 */
contract DB  {
    //lib using list

	struct UserInfo {
		uint id;
        address code;
		address rCode;
	}

	uint _uid = 0;
	mapping(uint => address) indexMapping;//UID address Mapping
    mapping(address => address) addressMapping;//inviteCode address Mapping
    mapping(address => UserInfo) userInfoMapping;//address UserInfo Mapping

    /**
     * @dev Create store user information
     * @param addr user addr
     * @param code user invite Code
     * @param rCode recommend code
     */
    function _registerUser(address addr, address code, address rCode)
        internal
    {
		UserInfo storage userInfo = userInfoMapping[addr];
        if (userInfo.id == 0) {
            if (_uid != 0) {
                require(isUsedCode(rCode), "DB: rCode not exist");
                address pAddr = addressMapping[rCode];
                require(pAddr != msg.sender, "DB: rCode can't be self");
                userInfo.rCode = rCode;
            }

            require(!isUsedCode(code), "DB: code is used");
            require(code != address(0), "DB: invalid invite code");

            _uid++;
            userInfo.id = _uid;
            userInfo.code = code;

            addressMapping[code] = addr;
            indexMapping[_uid] = addr;
        }
	}

    /**
     * @dev determine if user invite code is use
     * @param code user invite Code
     * @return bool
     */
    function _isUsedCode(address code)
        internal
        view
        returns (bool)
    {
		return addressMapping[code] != address(0);
	}

    /**
     * @dev get the user address of the corresponding user invite code
     * Authorization Required
     * @param code user invite Code
     * @return address
     */
    function _getCodeMapping(address code)
        internal
        view
        returns (address)
    {
		return addressMapping[code];
	}

    /**
     * @dev get the user address of the corresponding user id
     * Authorization Required
     * @param uid user id
     * @return address
     */
    function _getIndexMapping(uint uid)
        internal
        view
        returns (address)
    {
		return indexMapping[uid];
	}

    /**
     * @dev get the user address of the corresponding User info
     * Authorization Required or addr is owner
     * @param addr user address
     * @return info info[id,status,level,levelStatus]
     * @return code code
     * @return rCode rCode
     */
    function _getUserInfo(address addr)
        internal
        view
        returns (uint[1] memory info, address code, address rCode)
    {
		UserInfo memory userInfo = userInfoMapping[addr];
		info[0] = userInfo.id;

		return (info, userInfo.code, userInfo.rCode);
	}

    /**
     * @dev get the current latest ID
     * Authorization Required
     * @return current uid
     */
    function _getCurrentUserID()
        internal
        view
        returns (uint)
    {
		return _uid;
	}

    /**
     * @dev determine if user invite code is use
     * @param code user invite Code
     * @return bool
     */
    function isUsedCode(address code)
        public
        view
        returns (bool)
    {
		return _isUsedCode(code);
	}
}


/**
 * @title Utillibrary
 * @dev This integrates the basic functions.
 */
contract Utillibrary is Token_StandardToken {
    //lib using list
	using SafeMath for *;
    using Address for address;

    //base param setting
    // uint internal ethWei = 1 ether;
    uint internal USDTWei = 10 ** 6;
    uint internal ETTWei = 10 ** 18;
    uint internal USDT_ETTWei_Ratio = 10 ** 12;

    constructor() 
        Token_StandardToken("EAS", "EAS", 11000000, 18, address(this))
        public
    {

    }

    /**
     * @dev modifier to scope access to a Contract (uses tx.origin and msg.sender)
     */
	modifier isHuman() {
		require(msg.sender == tx.origin, "humans only");
		_;
	}

    /**
     * @dev check Zero Addr
     */
	modifier checkZeroAddr(address addr) {
		require(addr != address(0), "zero addr");
		_;
	}

    /**
     * @dev check Addr is Contract
     */
	modifier checkIsContract(address addr) {
		require(addr.isContract(), "not token addr");
		_;
	}

    /**
     * @dev check User ID
     * @param uid user ID
     */
    function checkUserID(uint uid)
        internal
        pure
    {
        require(uid != 0, "user not exist");
	}

    /**
     * @dev Transfer to designated user
     * @param _addr user address
     * @param _val transfer-out amount
     */
	function sendTokenToUser(address _addr, uint _val)
        internal
    {
		if (_val > 0) {
            _transfer(address(this), _addr, _val);//erc20 internal Function
		}
	}

    /**
     * @dev Gets the amount from the specified user
     * @param _addr user address
     * @param _val transfer-get amount
     */
	function getTokenFormUser(address _addr, uint _val)
        internal
    {
		if (_val > 0) {
            _transfer(_addr, address(this), _val);//erc20 internal Function
		}
	}

    /**
     * @dev Transfer to designated user
     * USDT transfer and transferFrom not returns
     * @param _taddr token address
     * @param _addr user address
     * @param _val transfer-out amount
     */
	function sendTokenToUser_USDT(address _taddr, address _addr, uint _val)
        internal
        checkZeroAddr(_addr)
        checkIsContract(_taddr)
    {
		if (_val > 0) {
            ITokenERC20_USDT(_taddr).transfer(_addr, _val);
		}
	}

    /**
     * @dev Gets the amount from the specified user
     * USDT transfer and transferFrom not returns
     * @param _taddr token address
     * @param _addr user address
     * @param _val transfer-get amount
     */
	function getTokenFormUser_USDT(address _taddr, address _addr, uint _val)
        internal
        checkZeroAddr(_addr)
        checkIsContract(_taddr)
    {
		if (_val > 0) {
            ITokenERC20_USDT(_taddr).transferFrom(_addr, address(this), _val);
		}
	}

    /**
     * @dev Check and correct transfer amount
     * @param sendMoney transfer-out amount
     * @return bool,amount
     */
	function isEnoughTokneBalance(address _taddr, uint sendMoney)
        internal
        view
        returns (bool, uint tokneBalance)
    {
        tokneBalance = ITokenERC20(_taddr).balanceOf(address(this));
		if (sendMoney > tokneBalance) {
			return (false, tokneBalance);
		} else {
			return (true, sendMoney);
		}
	}

    /**
     * @dev get Resonance Ratio for the Resonance ID
     * @param value Resonance ID
     * @return Resonance Ratio
     */
	function getResonanceRatio(uint value)
        internal
        view
        returns (uint)
    {
        // base 1U=10E
        // 1.10U=100E => 10/100U=1E => 1U=100/10E
        // 2.11U=100E => 11/100U=1E => 1U=100/11E
        // 3.12U=100E => 12/100U=1E => 1U=100/12E
        return USDT_ETTWei_Ratio * 100 / ((value - 1) + 10);
	}

    /**
     * @dev get scale for the level (*scale/1000)
     * @param level level
     * @return scale
     */
	function getScaleByLevel(uint level)
        internal
        pure
        returns (uint)
    {
		if (level == 1) {
			return 10;
		}
		if (level == 2) {
			return 12;
		}
		if (level == 3) {
			return 15;
		}
        if (level == 4) {
			return 15;
		}
		return 0;
	}

    /**
     * @dev get scale for the DailyDividend (*scale/1000)
     * @param level level
     * @return scale algebra
     */
	function getScaleByDailyDividend(uint level)
        internal
        pure
        returns (uint scale, uint algebra)
    {
		if (level == 1) {
			return (100, 1);
		}
		if (level == 2) {
			return (60, 5);
		}
		if (level == 3) {
            return (80, 8);
		}
        if (level == 4) {
            return (100, 10);
		}
		return (0, 0);
	}
}

contract EASContract is Utillibrary, DB {
    using SafeMath for *;

    //struct
	struct User {
		uint id;

        uint investAmountAddup;//add up invest Amount
        uint investAmountOut;//add up invest Amount Out

        uint investMoney;//invest amount current
        uint investAddupStaticBonus;//add up settlement static bonus amonut
        uint investAddupDynamicBonus;//add up settlement dynamic bonus amonut
        uint8 investOutMultiple;//invest Exit multiple of investment  n/10
        uint8 investLevel;//invest level
        uint40 investTime;//invest time
        uint40 investLastRwTime;//last settlement time

        uint bonusStaticAmount;//add up static bonus amonut (static bonus)
		uint bonusDynamicAmonut;//add up dynamic bonus amonut (dynamic bonus)

        uint takeBonusWallet;//takeBonus Wallet
        uint takeBonusAddup;//add up takeBonus
	}
    struct ResonanceData {
        uint40 time;//Resonance time
        uint ratio;//Resonance amount
        uint investMoney;//invest amount
	}

    //Loglist
    event InvestEvent(address indexed _addr, address indexed _code, address indexed _rCode, uint _value, uint time);
    event TakeBonusEvent(address indexed _addr, uint _type, uint _value_USDT, uint _value_ETT, uint time);

    //ERC Token addr
    address USDTToken;//USDT contract

    //base param setting
	address devAddr;//The special account

    //resonance
    uint internal rid = 1;//sell Round id
    mapping(uint => ResonanceData) internal resonanceDataMapping;//RoundID ResonanceData Mapping

    //address User Mapping
	mapping(address => User) userMapping;

    //addup
    uint AddupInvestUSD = 0;

    //ETT Token Pool
    uint ETTPool_User = ETTWei * 9900000;

    uint ETTPool_Dev = ETTWei * 1100000;
    uint ETTPool_Dev_RwAddup = 0;
    uint40 ETTPool_Dev_LastRwTime = uint40(now + 365 * 1 days);

    /**
     * @dev the content of contract is Beginning
     */
	constructor (
        address _devAddr,
        address _USDTAddr
    )
        public
    {
        //set addr
        devAddr = _devAddr;
        USDTToken = _USDTAddr;

        //init ResonanceData
        ResonanceData storage resonance = resonanceDataMapping[rid];
        if (resonance.ratio == 0) {
            resonance.time = uint40(now);
            resonance.ratio = getResonanceRatio(rid);
        }
    }

    /**
     * @dev the invest of contract is Beginning
     * @param money USDT amount for invest
     * @param rCode recommend code
     */
	function invest(uint money, address rCode)
        public
        isHuman()
    {
        address code = msg.sender;

        //判断是投资范围
        require(
            money == USDTWei * 2000
            || money == USDTWei * 1000
            || money == USDTWei * 500
            || money == USDTWei * 100
            , "invalid invest range");

        //init userInfo
        uint[1] memory user_data;
        (user_data, , ) = _getUserInfo(msg.sender);
        uint user_id = user_data[0];
		if (user_id == 0) {
			_registerUser(msg.sender, code, rCode);
            (user_data, , ) = _getUserInfo(msg.sender);
            user_id = user_data[0];
		}

		User storage user = userMapping[msg.sender];
		if (user.id == 0) {
            user.id = user_id;
		}

        //判断是已投资
        require(user.investMoney == 0, "Has been invested");

        //投资等级
        uint8 investLevel = 0;
        if(money == USDTWei * 2000) {
            investLevel = 4;
        } else if(money == USDTWei * 1000) {
            investLevel = 3;
        } else if(money == USDTWei * 500) {
            investLevel = 2;
        } else if(money == USDTWei * 100) {
            investLevel = 1;
        }
        require(investLevel >= user.investLevel,"invalid invest Level");

        if(AddupInvestUSD < USDTWei * 500000) {
            //Transfer USDT Token to Contract
            getTokenFormUser_USDT(USDTToken, msg.sender, money);
        } else {
            uint ETTMoney = money.mul(resonanceDataMapping[rid].ratio).mul(30).div(100);

            //Transfer USDT Token to Contract
            getTokenFormUser_USDT(USDTToken, msg.sender, money.mul(70).div(100));
            //Transfer ETT Token to Contract
            getTokenFormUser(msg.sender, ETTMoney);

            //add user Token pool
            ETTPool_User += ETTMoney;
        }

        //send USDT Token to dev addr
        sendTokenToUser_USDT(USDTToken, devAddr, money.div(20));

        //addup
        AddupInvestUSD += money;

        //user invest info
        user.investAmountAddup += money;
        user.investMoney = money;
        user.investAddupStaticBonus = 0;
        user.investAddupDynamicBonus = 0;
        user.investOutMultiple = 22;
        user.investLevel = investLevel;
        user.investTime = uint40(now);
        user.investLastRwTime = uint40(now);

        //update Ratio
        updateRatio(money);

        //触发更新直推投资出局倍数
        updateUser_Parent(rCode, money);

        emit InvestEvent(msg.sender, code, rCode, money, now);
	}

    /**
     * @dev settlement
     */
    function settlement()
        public
        isHuman()
    {
		User storage user = userMapping[msg.sender];
        checkUserID(user.id);

        require(user.investMoney > 0, "uninvested or out");
        require(now >= user.investLastRwTime, "not release time");

        //reacquire rCode
        address rCode;
        (, , rCode) = _getUserInfo(msg.sender);

        //-----------Static Start
        uint settlementNumber_base = (now - user.investLastRwTime) / 1 days;
        if (user.investMoney > 0 && settlementNumber_base > 0) 
        {
            uint moneyBonus_base = user.investMoney * getScaleByLevel(user.investLevel) / 1000;
            uint settlementNumber = settlementNumber_base;
            uint settlementMaxMoney = 0;
            if(user.investMoney * user.investOutMultiple / 10 >= user.investAddupStaticBonus + user.investAddupDynamicBonus) {
                settlementMaxMoney = user.investMoney * user.investOutMultiple / 10 - (user.investAddupStaticBonus + user.investAddupDynamicBonus);
            }
            uint moneyBonus = 0;
            if (moneyBonus_base * settlementNumber > settlementMaxMoney) 
            {
                settlementNumber = settlementMaxMoney / moneyBonus_base;
                if (moneyBonus_base * settlementNumber < settlementMaxMoney) {
                    settlementNumber ++;
                }
                if (settlementNumber > settlementNumber_base) {
                    settlementNumber = settlementNumber_base;
                }
                // moneyBonus = moneyBonus_base * settlementNumber;
                moneyBonus = settlementMaxMoney;
            } else {
                moneyBonus = moneyBonus_base * settlementNumber;
            }

            user.takeBonusWallet += moneyBonus;
            user.bonusStaticAmount += moneyBonus;

            user.investAddupStaticBonus += moneyBonus;
            user.investLastRwTime += uint40(settlementNumber * 1 days);
            //check out
            if (user.investAddupStaticBonus + user.investAddupDynamicBonus >= user.investMoney * user.investOutMultiple / 10) {
                user.investAmountOut += user.investMoney;
                user.investMoney = 0;//out
            }

            //Calculate the bonus (Daily Dividend)
            // countBonus_DailyDividend(rCode, moneyBonus, user.investMoney);
            countBonus_DailyDividend(rCode, moneyBonus_base * settlementNumber, user.investMoney);
        }
        //-----------Static End
	}

    /**
     * @dev the take bonus of contract is Beginning
     * @param _type take type 0:default 100%USDT, 1:30%ETT 70%USDT, 2:50%ETT 50%USDT, 3:70%ETT 30%USDT, 4:100%ETT 0%USDT
     */
    function takeBonus(uint8 _type)
        public
        isHuman()
    {
		User storage user = userMapping[msg.sender];
		checkUserID(user.id);

		require(user.takeBonusWallet >= USDTWei * 1, "invalid amount");

        uint sendDevMoney_USDT = user.takeBonusWallet.div(20);
		uint takeMoney_USDT = user.takeBonusWallet.sub(sendDevMoney_USDT);
        uint takeMoney_USDT_ETT = 0;

        //Calculation amount
        (takeMoney_USDT, takeMoney_USDT_ETT) = calculationTakeBonus(_type, takeMoney_USDT);

        bool isEnoughBalance = false;
        uint resultMoney = 0;

        //check send USDT
        //check USDT Enough Balance
        (isEnoughBalance, resultMoney) = isEnoughTokneBalance(USDTToken, takeMoney_USDT + sendDevMoney_USDT);
        if(isEnoughBalance == false)
        {
            require(resultMoney > 0, "not Enough Balance USDT");
            //correct
            sendDevMoney_USDT = resultMoney.div(20);
            takeMoney_USDT = resultMoney.sub(sendDevMoney_USDT);
            //Calculation amount
            (takeMoney_USDT, takeMoney_USDT_ETT) = calculationTakeBonus(_type, takeMoney_USDT);
        }

        //check send ETT
        if(takeMoney_USDT_ETT > 0)
        {
            uint ETTMoney = takeMoney_USDT_ETT.mul(resonanceDataMapping[rid].ratio);
            //check user Token pool
            if(ETTMoney > ETTPool_User) {
                ETTMoney = ETTPool_User;
                require(ETTMoney > 0, "not Enough Balance pool");
                //correct
                uint ETTMoney_USDT = ETTMoney.div(resonanceDataMapping[rid].ratio);
                sendDevMoney_USDT = sendDevMoney_USDT.mul(ETTMoney_USDT).div(takeMoney_USDT_ETT);
                takeMoney_USDT = takeMoney_USDT.mul(ETTMoney_USDT).div(takeMoney_USDT_ETT);
                takeMoney_USDT_ETT = ETTMoney_USDT;
            }

            //check ETT Enough Balance
            (isEnoughBalance, resultMoney) = isEnoughTokneBalance(address(this), ETTMoney);
            if(isEnoughBalance == false)
            {
                require(resultMoney > 0, "not Enough Balance ETT");
                //correct
                uint resultMoney_USDT = resultMoney.div(resonanceDataMapping[rid].ratio);
                sendDevMoney_USDT = sendDevMoney_USDT.mul(resultMoney_USDT).div(takeMoney_USDT_ETT);
                takeMoney_USDT = takeMoney_USDT.mul(resultMoney_USDT).div(takeMoney_USDT_ETT);
                takeMoney_USDT_ETT = resultMoney_USDT;
            }
        }

        if(sendDevMoney_USDT > 0)
        {
            //Transfer USDT Token to Dev
            sendTokenToUser_USDT(USDTToken, devAddr, sendDevMoney_USDT);
        }
        if(takeMoney_USDT > 0)
        {
            //Transfer USDT Token to User
            sendTokenToUser_USDT(USDTToken, msg.sender, takeMoney_USDT);
        }
        if(takeMoney_USDT_ETT > 0)
        {
            //Transfer ETT Token to User
            sendTokenToUser(msg.sender, takeMoney_USDT_ETT.mul(resonanceDataMapping[rid].ratio));
            ETTPool_User = ETTPool_User.sub(takeMoney_USDT_ETT.mul(resonanceDataMapping[rid].ratio));
        }

        user.takeBonusWallet = user.takeBonusWallet.sub(takeMoney_USDT).sub(takeMoney_USDT_ETT).sub(sendDevMoney_USDT);
        user.takeBonusAddup = user.takeBonusAddup.add(takeMoney_USDT).add(takeMoney_USDT_ETT).add(sendDevMoney_USDT);

        emit TakeBonusEvent(msg.sender, _type, takeMoney_USDT, takeMoney_USDT_ETT, now);
	}

    /**
     * @dev settlement ETT Pool Dev
     */
    function settlement_Dev()
        public
        isHuman()
    {
        require(now >= ETTPool_Dev_LastRwTime, "not release time");
        require(ETTPool_Dev > ETTPool_Dev_RwAddup, "release done");
        
        uint settlementNumber_base =  (now - ETTPool_Dev_LastRwTime) / 1 days;
        uint moneyBonus_base = ETTPool_Dev / 365;
        uint settlementNumber = settlementNumber_base;
        uint settlementMaxMoney = 0;
        if(ETTPool_Dev >= ETTPool_Dev_RwAddup) {
            settlementMaxMoney = ETTPool_Dev - ETTPool_Dev_RwAddup;
        }
        uint moneyBonus = 0;
        if (moneyBonus_base * settlementNumber > settlementMaxMoney) 
        {
            settlementNumber = settlementMaxMoney / moneyBonus_base;
            if (moneyBonus_base * settlementNumber < settlementMaxMoney) {
                settlementNumber ++;
            }
            if (settlementNumber > settlementNumber_base) {
                settlementNumber = settlementNumber_base;
            }
            // moneyBonus = moneyBonus_base * settlementNumber;
            moneyBonus = settlementMaxMoney;
        } else {
            moneyBonus = moneyBonus_base * settlementNumber;
        }

        //Transfer ETT Token to Dev
        sendTokenToUser(devAddr, moneyBonus);

        //update Dev_Rw
        ETTPool_Dev_RwAddup += moneyBonus;
        ETTPool_Dev_LastRwTime += uint40(settlementNumber * 1 days);
	}

    /**
     * @dev Show contract state view
     * @return info contract state view
     */
    function stateView()
        public
        view
        returns (uint[8] memory info)
    {
        info[0] = _getCurrentUserID();
        info[1] = rid;
        info[2] = resonanceDataMapping[rid].ratio;
        info[3] = resonanceDataMapping[rid].investMoney;
        info[4] = resonanceDataMapping[rid].time;
        info[5] = AddupInvestUSD;
        info[6] = ETTPool_Dev_RwAddup;
        info[7] = ETTPool_Dev_LastRwTime;

		return (info);
	}

    /**
     * @dev get the user info based
     * @param addr user addressrd
     * @return info user info
     */
	function getUserByAddress(
        address addr
    )
        public
        view
        returns (uint[14] memory info, address code, address rCode)
    {
        uint[1] memory user_data;
        (user_data, code, rCode) = _getUserInfo(addr);
        uint user_id = user_data[0];

		User storage user = userMapping[addr];

		info[0] = user_id;
        info[1] = user.investAmountAddup;
        info[2] = user.investAmountOut;
        info[3] = user.investMoney;
        info[4] = user.investAddupStaticBonus;
        info[5] = user.investAddupDynamicBonus;
        info[6] = user.investOutMultiple;
        info[7] = user.investLevel;
        info[8] = user.investTime;
        info[9] = user.investLastRwTime;
        info[10] = user.bonusStaticAmount;
        info[11] = user.bonusDynamicAmonut;
        info[12] = user.takeBonusWallet;
        info[13] = user.takeBonusAddup;
		return (info, code, rCode);
	}

    /**
     * @dev update Resonance Ratio
     * @param investMoney invest USDT amount
     */
	function updateRatio(uint investMoney)
        private
    {
        ResonanceData storage resonance = resonanceDataMapping[rid];
        resonance.investMoney += investMoney;

        //check
        if(AddupInvestUSD >= USDTWei * 500000)
        {
            uint newRatio = 0;
            uint newResonanceInvestMoney = 0;
            if(rid == 1)
            {
                if(resonance.investMoney >= USDTWei * 600000)
                {
                    newResonanceInvestMoney = resonance.investMoney - USDTWei * 600000;
                    resonance.investMoney = USDTWei * 600000;
                    newRatio = getResonanceRatio(rid + 1);
                }
            } else {
                if(resonance.investMoney >= USDTWei * 100000)
                {
                    newResonanceInvestMoney = resonance.investMoney - USDTWei * 100000;
                    resonance.investMoney = USDTWei * 100000;
                    newRatio = getResonanceRatio(rid + 1);
                }
            }

            if (newRatio > 0) 
            {
                rid ++;
                resonance = resonanceDataMapping[rid];
                resonance.time = uint40(now);
                resonance.ratio = newRatio;
                //Continuous rise
                resonance.investMoney = newResonanceInvestMoney;
                updateRatio(0);
            }
        }
	}

        /**
     * @dev update Parent User
     * @param rCode user recommend code
     * @param money invest money
     */
	function updateUser_Parent(address rCode, uint money)
        private
    {
		if (rCode == address(0)) {
            return;
        }

        User storage user = userMapping[rCode];

        //-----------updateUser_Parent Start
        if (user.investMoney > 0 && money >= user.investMoney) {
            user.investOutMultiple = 30;
        }
        //-----------updateUser_Parent End
	}

    /**
     * @dev Calculate the bonus (Daily Dividend)
     * @param rCode user recommend code
     * @param money base money
     * @param investMoney invest money
     */
	function countBonus_DailyDividend(address rCode, uint money, uint investMoney)
        private
    {
		address tmpReferrerCode = rCode;
        address tmpUser_rCode;

		for (uint i = 1; i <= 10; i++) {
			if (tmpReferrerCode == address(0)) {
				break;
			}

			User storage user = userMapping[tmpReferrerCode];

            //last rRcode and currUserInfo
            (, , tmpUser_rCode) = _getUserInfo(tmpReferrerCode);

            //-----------DailyDividend Start
            if (user.investMoney > 0) 
            {
                uint moneyBonusDailyDividend = 0;

                (uint scale, uint algebra) = getScaleByDailyDividend(user.investLevel);
                if (algebra >= i) 
                {
                    moneyBonusDailyDividend = money * scale / 1000;
                    //burns
                    if (user.investMoney < investMoney) {
                        moneyBonusDailyDividend = moneyBonusDailyDividend * user.investMoney / investMoney;
                    }
                    if (moneyBonusDailyDividend > 0) {
                        //check out

                        if (user.investAddupStaticBonus + user.investAddupDynamicBonus + moneyBonusDailyDividend >= user.investMoney * user.investOutMultiple / 10) {
                            moneyBonusDailyDividend = user.investMoney * user.investOutMultiple / 10 - (user.investAddupStaticBonus + user.investAddupDynamicBonus);

                            user.investAmountOut += user.investMoney;
                            user.investMoney = 0;//out
                        }
                        user.takeBonusWallet += moneyBonusDailyDividend;
                        user.bonusDynamicAmonut += moneyBonusDailyDividend;
                        user.investAddupDynamicBonus += moneyBonusDailyDividend;
                    }
                }
            }
            //-----------DailyDividend End

            tmpReferrerCode = tmpUser_rCode;
		}
	}


    /**
     * @dev Calculation amount
     * @param _type take type
     * @param takeMoney take Money
     * @return takeMoney_USDT take Money USDT
     * @return takeMoney_USDT_ETT take Money USDT(ETT)
     */
	function calculationTakeBonus(uint8 _type, uint takeMoney)
        internal
        pure
        returns (uint takeMoney_USDT, uint takeMoney_USDT_ETT)
    {
		takeMoney_USDT = takeMoney;

        if(_type == 1) {
            //ETT 30%
            takeMoney_USDT_ETT = takeMoney_USDT.mul(30).div(100);
        }
        else if(_type == 2) {
            //ETT 50%
            takeMoney_USDT_ETT = takeMoney_USDT.div(2);
        }
        else if(_type == 3) {
            //ETT 70%
            takeMoney_USDT_ETT = takeMoney_USDT.mul(70).div(100);
        }
        else if(_type == 4) {
            //ETT 100%
            takeMoney_USDT_ETT = takeMoney_USDT;
        }
        takeMoney_USDT = takeMoney_USDT.sub(takeMoney_USDT_ETT);
	}
}