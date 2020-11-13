pragma solidity 0.5.17;

/* import "./GAMERTokenInterface.sol"; */
import "./GAMERGovernance.sol";

contract GAMERToken is GAMERGovernanceToken {
    // Modifiers
    modifier onlyGov() {
        require(msg.sender == gov, 'not gov');
        _;
    }

    modifier onlyRebaser() {
        require(msg.sender == rebaser);
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == rebaser || msg.sender == incentivizer || msg.sender == stakingPool || msg.sender == teamPool || msg.sender == dev || msg.sender == gov, "not minter");
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )
        public
    {
        require(gamersScalingFactor == 0, "already initialized");
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /**
    * @notice Computes the current totalSupply
    */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply.div(10**24/ (BASE));
    }
    
    /**
    * @notice Computes the current max scaling factor
    */
    function maxScalingFactor()
        external
        view
        returns (uint256)
    {
        return _maxScalingFactor();
    }

    function _maxScalingFactor()
        internal
        view
        returns (uint256)
    {
        // scaling factor can only go up to 2**256-1 = initSupply * gamersScalingFactor
        // this is used to check if gamersScalingFactor will be too high to compute balances when rebasing.
        return uint256(-1) / initSupply;
    }

    /**
    * @notice Mints new tokens, increasing totalSupply, initSupply, and a users balance.
    * @dev Limited to onlyMinter modifier
    */
    function mint(address to, uint256 amount)
        external
        onlyMinter
        returns (bool)
    {
        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount)
        internal
    {
      // increase totalSupply
      _totalSupply = _totalSupply.add(amount.mul(10**24/ (BASE)));

      // get underlying value
      uint256 gamerValue = amount.mul(internalDecimals).div(gamersScalingFactor);

      // increase initSupply
      initSupply = initSupply.add(gamerValue);

      // make sure the mint didnt push maxScalingFactor too low
      require(gamersScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

      // add balance
      _gamerBalances[to] = _gamerBalances[to].add(gamerValue);
      emit Transfer(address(0), to, amount);
    
      // add delegates to the minter
      _moveDelegates(address(0), _delegates[to], gamerValue);
      emit Mint(to, amount);
    }

    /* - ERC20 functionality - */

    /**
    * @dev Transfer tokens to a specified address.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return True on success, false otherwise.
    */
    function transfer(address to, uint256 value)
        external
        validRecipient(to)
        returns (bool)
    {
        // underlying balance is stored in gamers, so divide by current scaling factor

        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == gamersScalingFactor / 1e24;

        // get amount in underlying
        uint256 gamerValue = value.mul(internalDecimals).div(gamersScalingFactor);

        // sub from balance of sender
        _gamerBalances[msg.sender] = _gamerBalances[msg.sender].sub(gamerValue);

        // add to balance of receiver
        _gamerBalances[to] = _gamerBalances[to].add(gamerValue);
        emit Transfer(msg.sender, to, value);

        _moveDelegates(_delegates[msg.sender], _delegates[to], gamerValue);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another.
    * @param from The address you want to send tokens from.
    * @param to The address you want to transfer to.
    * @param value The amount of tokens to be transferred.
    */
    function transferFrom(address from, address to, uint256 value)
        external
        validRecipient(to)
        returns (bool)
    {
        // decrease allowance
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        // get value in gamers
        uint256 gamerValue = value.mul(internalDecimals).div(gamersScalingFactor);

        // sub from from
        _gamerBalances[from] = _gamerBalances[from].sub(gamerValue);
        _gamerBalances[to] = _gamerBalances[to].add(gamerValue);
        emit Transfer(from, to, value);

        _moveDelegates(_delegates[from], _delegates[to], gamerValue);
        return true;
    }

    /**
    * @param who The address to query.
    * @return The balance of the specified address.
    */
    function balanceOf(address who)
      external
      view
      returns (uint256)
    {
      return _gamerBalances[who].mul(gamersScalingFactor).div(internalDecimals);
    }

    /** @notice Currently returns the internal storage amount
    * @param who The address to query.
    * @return The underlying balance of the specified address.
    */
    function balanceOfUnderlying(address who)
      external
      view
      returns (uint256)
    {
      return _gamerBalances[who];
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /* - Governance Functions - */

    /** @notice sets the rebaser
     * @param rebaser_ The address of the rebaser contract to use for authentication.
     */
    function _setRebaser(address rebaser_)
        external
        onlyGov
    {
        address oldRebaser = rebaser;
        rebaser = rebaser_;
        emit NewRebaser(oldRebaser, rebaser_);
    }

    /** @notice sets the incentivizer
     * @param incentivizer_ The address of the incentivizer contract to use for authentication.
     */
    function _setIncentivizer(address incentivizer_)
        external
        onlyGov
    {
        address oldIncentivizer = incentivizer;
        incentivizer = incentivizer_;
        emit NewIncentivizer(oldIncentivizer, incentivizer_);
    }

    /** @notice sets the stakingPool
     * @param stakingPool_ The address of the stakingPool contract to use for authentication.
     */
    function _setStakingPool(address stakingPool_)
        external
        onlyGov
    {
        address oldStakingPool = stakingPool;
        stakingPool = stakingPool_;
        emit NewStakingPool(oldStakingPool, stakingPool_);
    }

    /** @notice sets the teamPool
     * @param teamPool_ The address of the teamPool contract to use for authentication.
     */
    function _setTeamPool(address teamPool_)
        external
        onlyGov
    {
        address oldTeamPool = teamPool;
        teamPool = teamPool_;
        emit NewTeamPool(oldTeamPool, teamPool_);
    }

    /** @notice sets the dev
     * @param dev_ The address of the dev contract to use for authentication.
     */
    function _setDev(address dev_)
        external
        onlyGov
    {
        address oldDev = dev;
        dev = dev_;
        emit NewDev(oldDev, dev_);
    }

    /** @notice sets the pendingGov
     * @param pendingGov_ The address of the rebaser contract to use for authentication.
     */
    function _setPendingGov(address pendingGov_)
        external
        onlyGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    /** @notice lets msg.sender accept governance
     *
     */
    function _acceptGov()
        external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    /* - Extras - */

    /**
    * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
    *
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    )
        external
        onlyRebaser
        returns (uint256)
    {
        if (indexDelta == 0) {
          emit Rebase(epoch, gamersScalingFactor, gamersScalingFactor);
          return _totalSupply;
        }

        uint256 prevGrapsScalingFactor = gamersScalingFactor;

        if (!positive) {
           gamersScalingFactor = gamersScalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
        } else {
            uint256 newScalingFactor = gamersScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                gamersScalingFactor = newScalingFactor;
            } else {
              gamersScalingFactor = _maxScalingFactor();
            }
        }

        _totalSupply = initSupply.mul(gamersScalingFactor).div(BASE);
        emit Rebase(epoch, prevGrapsScalingFactor, gamersScalingFactor);
        return _totalSupply;
    }
}

contract GAMER is GAMERToken {
    /**
     * @notice Initialize the new money market
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initial_owner,
        uint256 initSupply_
    )
        public
    {
        require(initSupply_ > 0, "0 init supply");

        super.initialize(name_, symbol_, decimals_);

        initSupply = initSupply_.mul(10**24/ (BASE));
        _totalSupply = initSupply;
        gamersScalingFactor = BASE;
        _gamerBalances[initial_owner] = initSupply_.mul(10**24 / (BASE));

        // owner renounces ownership after deployment as they need to set
        // rebaser and incentivizer
        // gov = gov_;
    }
}
