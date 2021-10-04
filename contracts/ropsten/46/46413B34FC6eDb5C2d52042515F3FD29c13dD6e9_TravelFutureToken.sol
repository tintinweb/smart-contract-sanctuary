/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

pragma solidity ^0.4.26;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

// File: zeppelin-solidity/contracts/token/BEP20Basic.sol

/**
 * @title BEP20Basic
 * @dev Simpler version of BEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */

contract BEP20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */

contract BasicToken is BEP20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.

        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

// File: zeppelin-solidity/contracts/token/BEP20.sol

/**
 * @title BEP20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

contract BEP20 is BEP20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: zeppelin-solidity/contracts/token/StandardToken.sol

/**
 * @title Standard BEP20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract StandardToken is BEP20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

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
    ) public returns (bool) {
        require(_to != address(0));

        require(_value <= balances[_from]);

        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }

    /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(
            _addedValue
        );

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */

    function _mint(address account, uint256 amount) public {
        require(account != address(0), "BEP20: mint to the zero address");

        // _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;

        balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
}

contract TravelFutureToken is StandardToken, Ownable {
    event AssignmentStopped();

    event Frosted(address indexed to, uint256 amount, uint256 defrostClass);

    event Defrosted(address indexed to, uint256 amount, uint256 defrostClass);

    using SafeMath for uint256;

    /* Overriding some BEP20 variables */

    string public constant name = "TravelFutureToken";

    string public constant symbol = "TFT";

    uint8 public constant decimals = 18;

    uint256 public constant MAX_NUM_TESTTOKENS =
        220000000 * 10**uint256(decimals);

    uint256 public constant START_ICO_TIMESTAMP = now; // TODO: line to uncomment for the PROD before the main net deployment

    //uint256 public START_ICO_TIMESTAMP; // TODO: !!! line to remove before the main net deployment (not constant for testing and overwritten in the constructor)

    uint256 public constant MONTH_IN_MINUTES = 43200; // month in minutes  (1month = 43200 min)

    uint256 public totalStrategicSupply;

    uint256 public totalPvt1Supply;

    uint256 public totalPvt2Supply;

    uint256 public totalAirdropSupply;

    uint256 public totalPublicSaleSupply;

    uint256 public monthIndex;

    bool public InitUnTrigger = true;

    uint256 public count;

    uint256 time_of_investment = now;

    enum DefrostClass {StrategicSale, PvtSale1, PvtSale2, PublicSale, Airdrop}

    // Fields that can be changed by functions

    address[] public icedBalancesStrategicSale;

    address[] public icedBalancesPvtSale1;

    address[] public icedBalancesPvtSale2;

    mapping(address => uint256) public mapicedBalancesStrategicSale;

    mapping(address => uint256) public mapicedBalancesPvtSale1;

    mapping(address => uint256) public mapicedBalancesPvtSale2;

    //Boolean to allow or not the initial assignement of token (batch)

    bool public batchAssignStopped = false;

    address public prelaunchAddress =
        0xc8177b2e074Bac81A5D968aCEA863B7Ff5bFC16b;

    address public teamAddress = 0x008EB585B4C55fCDd030cfB0eE12cF233c4E88e8;

    address public foundationAddress =
        0xF0BeDC89B2316597587B09376635435D65180eE3;

    address public bussinessAddress =
        0xB6AE9d0aC16C2136b4dEB8b7B9893fe8131989a1;

    address public incentiveAddress =
        0xcB9c7Cbc97155ab3e16De759A01Dff1983e266d6;

    address public circulationAddress =
        0xcB9c7Cbc97155ab3e16De759A01Dff1983e266d6;

    uint256 prelaunchSupply = 10000000 * 10**18;

    uint256 teamSupply = 8000000 * 10**18;

    uint256 foundationSupply = 14000000 * 10**18;

    uint256 bussinessSupply = 52000000 * 10**18;

    uint256 incentiveSupply = 10000000 * 10**18;

    uint256 circulationSupply = 6000000 * 10**18;

    uint256 unlockedPerQuarter = 2000000 * 10**18;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */

    constructor() {
        // for test only: set START_ICO to contract creation timestamp

        //START_ICO_TIMESTAMP = now; // TODO: line to remove before the main net deployment

        _mint(prelaunchAddress, prelaunchSupply);

        _mint(teamAddress, teamSupply);

        _mint(foundationAddress, foundationSupply);

        _mint(bussinessAddress, bussinessSupply);

        _mint(incentiveAddress, incentiveSupply);

        _mint(circulationAddress, circulationSupply);
    }

    modifier canAssign() {
        require(!batchAssignStopped);

        //require(elapsedMonthsFromICOStart() < 2);

        _;
    }

    function batchAssignTokens(
        address[] _addr,
        uint256[] _amounts,
        DefrostClass[] _defrostClass
    ) public onlyOwner canAssign {
        require(
            _addr.length == _amounts.length &&
                _addr.length == _defrostClass.length
        );

        //Looping into input arrays to assign target amount to each given address

        for (uint256 index = 0; index < _addr.length; index++) {
            address toAddress = _addr[index];

            uint256 amount = _amounts[index];

            DefrostClass defrostClass = _defrostClass[index]; /* 0 = StrategicSale, 1 = PvtSale1, 2 = PvtSale2, 
            3 = PublicSale, 4 = Airdrop */

            totalSupply = totalSupply.add(amount);

            require(totalSupply <= MAX_NUM_TESTTOKENS);

            if (
                defrostClass == DefrostClass.PublicSale ||
                defrostClass == DefrostClass.Airdrop
            ) {
                require(
                    totalPublicSaleSupply <= 6000000 &&
                        totalAirdropSupply <= 3000000
                );

                balances[toAddress] = balances[toAddress].add(amount);

                if (defrostClass == DefrostClass.PublicSale) {
                    totalPublicSaleSupply = totalPublicSaleSupply.add(amount);

                    Defrosted(
                        toAddress,
                        amount,
                        uint256(DefrostClass.PublicSale)
                    );
                }

                if (defrostClass == DefrostClass.Airdrop) {
                    totalAirdropSupply = totalAirdropSupply.add(amount);

                    Defrosted(toAddress, amount, uint256(DefrostClass.Airdrop));
                }

                Transfer(address(0), toAddress, amount);
            } else if (defrostClass == DefrostClass.StrategicSale) {
                icedBalancesStrategicSale.push(toAddress);

                mapicedBalancesStrategicSale[
                    toAddress
                ] = mapicedBalancesStrategicSale[toAddress].add(amount);

                Frosted(toAddress, amount, uint256(defrostClass));
            } else if (defrostClass == DefrostClass.PvtSale1) {
                icedBalancesPvtSale1.push(toAddress);

                mapicedBalancesPvtSale1[toAddress] = mapicedBalancesPvtSale1[
                    toAddress
                ]
                    .add(amount);

                Frosted(toAddress, amount, uint256(defrostClass));
            } else if (defrostClass == DefrostClass.PvtSale2) {
                icedBalancesPvtSale2.push(toAddress);

                mapicedBalancesPvtSale2[toAddress] = mapicedBalancesPvtSale2[
                    toAddress
                ]
                    .add(amount);

                Frosted(toAddress, amount, uint256(defrostClass));
            }
        }

        icedBalancesStrategicSale = filterAddress(icedBalancesStrategicSale);

        icedBalancesPvtSale1 = filterAddress(icedBalancesPvtSale1);

        icedBalancesPvtSale2 = filterAddress(icedBalancesPvtSale2);
    }

    function defrostTokens() public {
        if (InitUnTrigger && InitTknUnlockStatus()) {
            stopBatchAssign();

            for (
                uint256 index = 0;
                index < icedBalancesStrategicSale.length;
                index++
            ) {
                address currentAddress = icedBalancesStrategicSale[index];

                uint256 amountToDefrost =
                    mapicedBalancesStrategicSale[currentAddress];

                if (amountToDefrost > 0) {
                    require(totalStrategicSupply <= 15000000);

                    amountToDefrost = amountToDefrost.mul(20).div(100);

                    balances[currentAddress] = balances[currentAddress].add(
                        amountToDefrost
                    );

                    //mapicedBalancesPvtSale1[currentAddress] = mapicedBalancesPvtSale1[currentAddress].sub(amountToDefrost);

                    totalStrategicSupply = totalStrategicSupply.add(
                        amountToDefrost
                    );

                    //Transfer(address(0), currentAddress, amountToDefrost);

                    Defrosted(
                        currentAddress,
                        amountToDefrost,
                        uint256(DefrostClass.StrategicSale)
                    );
                }
            }

            for (index = 0; index < icedBalancesPvtSale1.length; index++) {
                currentAddress = icedBalancesPvtSale1[index];

                amountToDefrost = mapicedBalancesPvtSale1[currentAddress];

                if (amountToDefrost > 0) {
                    require(totalPvt1Supply <= 37500000);

                    amountToDefrost = amountToDefrost.mul(25).div(100);

                    balances[currentAddress] = balances[currentAddress].add(
                        amountToDefrost
                    );

                    //mapicedBalancesPvtSale1[currentAddress] = mapicedBalancesPvtSale1[currentAddress].sub(amountToDefrost);

                    totalPvt1Supply = totalPvt1Supply.add(amountToDefrost);

                    //Transfer(address(0), currentAddress, amountToDefrost);

                    Defrosted(
                        currentAddress,
                        amountToDefrost,
                        uint256(DefrostClass.PvtSale1)
                    );
                }
            }

            for (index = 0; index < icedBalancesPvtSale2.length; index++) {
                currentAddress = icedBalancesPvtSale2[index];

                amountToDefrost = mapicedBalancesPvtSale2[currentAddress];

                if (amountToDefrost > 0) {
                    require(totalPvt2Supply <= 7500000);

                    amountToDefrost = amountToDefrost.mul(25).div(100);

                    balances[currentAddress] = balances[currentAddress].add(
                        amountToDefrost
                    );

                    //mapicedBalancesPvtSale2[currentAddress] = mapicedBalancesPvtSale2[currentAddress].sub(amountToDefrost);

                    totalPvt2Supply = totalPvt2Supply.add(amountToDefrost);

                    //Transfer(address(0), currentAddress, amountToDefrost);

                    Defrosted(
                        currentAddress,
                        amountToDefrost,
                        uint256(DefrostClass.PvtSale2)
                    );
                }
            }

            InitUnTrigger = false;
        }

        if (CycleTknUnlockStatus()) {
            for (index = 0; index < icedBalancesStrategicSale.length; index++) {
                currentAddress = icedBalancesStrategicSale[index];

                amountToDefrost = mapicedBalancesStrategicSale[currentAddress];

                if (amountToDefrost > 0) {
                    require(totalStrategicSupply <= 15000000);

                    amountToDefrost = amountToDefrost.mul(8).div(100);

                    balances[currentAddress] = balances[currentAddress].add(
                        amountToDefrost
                    );

                    //mapicedBalancesStrategicSale[currentAddress] = mapicedBalancesStrategicSale[currentAddress].sub(amountToDefrost);

                    totalStrategicSupply = totalStrategicSupply.add(
                        amountToDefrost
                    );

                    //Transfer(address(0), currentAddress, amountToDefrost);

                    Defrosted(
                        currentAddress,
                        amountToDefrost,
                        uint256(DefrostClass.StrategicSale)
                    );
                }
            }

            for (index = 0; index < icedBalancesPvtSale1.length; index++) {
                currentAddress = icedBalancesPvtSale1[index];

                amountToDefrost = mapicedBalancesPvtSale1[currentAddress];

                if (amountToDefrost > 0) {
                    require(totalPvt1Supply <= 37500000);

                    amountToDefrost = amountToDefrost.mul(75).div(1000);

                    balances[currentAddress] = balances[currentAddress].add(
                        amountToDefrost
                    );

                    //mapicedBalancesPvtSale1[currentAddress] = mapicedBalancesPvtSale1[currentAddress].sub(amountToDefrost);

                    totalPvt1Supply = totalPvt1Supply.add(amountToDefrost);

                    //Transfer(address(0), currentAddress, amountToDefrost);

                    Defrosted(
                        currentAddress,
                        amountToDefrost,
                        uint256(DefrostClass.PvtSale1)
                    );
                }
            }

            for (index = 0; index < icedBalancesPvtSale2.length; index++) {
                currentAddress = icedBalancesPvtSale2[index];

                amountToDefrost = mapicedBalancesPvtSale2[currentAddress];

                if (amountToDefrost > 0) {
                    require(totalPvt2Supply <= 7500000);

                    amountToDefrost = amountToDefrost.mul(75).div(1000);

                    balances[currentAddress] = balances[currentAddress].add(
                        amountToDefrost
                    );

                    //mapicedBalancesPvtSale2[currentAddress] = mapicedBalancesPvtSale2[currentAddress].sub(amountToDefrost);

                    totalPvt2Supply = totalPvt2Supply.add(amountToDefrost);

                    //Transfer(address(0), currentAddress, amountToDefrost);

                    Defrosted(
                        currentAddress,
                        amountToDefrost,
                        uint256(DefrostClass.PvtSale2)
                    );
                }
            }
        }
    }

    function InitTknUnlockStatus() public view returns (bool) {
        if (count <= 1) {
            if (now >= time_of_investment + (3 * 60 * 60 * MONTH_IN_MINUTES)) {
                monthIndex = 4;

                count = 2;

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    //The cycletkn unlock function will only run if InitTkn is executed

    function CycleTknUnlockStatus() public view returns (bool) {
        if ((monthIndex > 3 && monthIndex <= 13)) {
            if (
                now >=
                time_of_investment + (monthIndex * 60 * 60 * MONTH_IN_MINUTES)
            ) {
                monthIndex++;

                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function filterAddress(address[] array) private returns (address[]) {
        for (uint256 index; index < array.length; index++) {
            if (array[index] != 0) {
                for (uint256 a = index + 1; a < array.length; a++) {
                    if (array[index] == array[a]) {
                        array[a] = 0;
                    }
                }
            }
        }

        return array;
    }

    function stopBatchAssign() public onlyOwner canAssign {
        batchAssignStopped = true;

        AssignmentStopped();
    }

    function() public payable {
        revert();
    }
}