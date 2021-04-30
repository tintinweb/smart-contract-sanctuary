// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import "./Utils.sol";

contract GriseToken is Utils {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address public LIQUIDITY_GATEKEEPER;
    address public STAKE_GATEKEEPER;
    address public VAULT_GATEKEEPER;

    address private liquidtyGateKeeper;
    address private stakeGateKeeper;
    address private vaultGateKeeper;

    /**
     * @dev initial private
     */
    string private _name;
    string private _symbol;
    uint8 private _decimal = 18;

    /**
     * @dev 👻 Initial supply 
     */
    uint256 private _totalSupply = 0;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor (string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
        liquidtyGateKeeper = _msgSender();
        stakeGateKeeper = _msgSender();
        vaultGateKeeper = _msgSender();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the token.
     */
    function decimals() external view returns (uint8) {
        return _decimal;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the token balance of specific address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool)
    {  
        _transfer(
            _msgSender(),
            recipient,
            amount
        );

        return true;
    }

    /**
     * @dev Returns approved balance to be spent by another address
     * by using transferFrom method
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets the token allowance to another spender
     */
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            amount
        );

        return true;
    }

    /**
     * @dev Allows to transfer tokens on senders behalf
     * based on allowance approved for the executer
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool)
    {    
        _approve(sender,
            _msgSender(), _allowances[sender][_msgSender()].sub(
                amount
            )
        );

        _transfer(
            sender,
            recipient,
            amount
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Emits a {Transfer} event.
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            sender != address(0x0)
        );

        require(
            recipient != address(0x0)
        );

        uint256 stFee;
        uint256 btFee;
        uint256 teamReward;
        uint256 currentGriseDay = _currentGriseDay();

        if (staker[sender] == 0) {
            stFee = _calculateSellTranscFee(amount);

            sellTranscFee[currentGriseDay] = 
            sellTranscFee[currentGriseDay]
                        .add(stFee);
                
            reservoirRewardPerShare[currentGriseDay] = 
            reservoirRewardPerShare[currentGriseDay]
                        .add(stFee.mul(TRANSC_RESERVOIR_REWARD)
                        .div(REWARD_PRECISION_RATE)
                        .div(mediumTermShares));
                
            stakerRewardPerShare[currentGriseDay] = 
            stakerRewardPerShare[currentGriseDay]
                        .add(stFee.mul(TRANSC_STAKER_REWARD)
                        .div(REWARD_PRECISION_RATE)
                        .div(mediumTermShares));
                
            tokenHolderReward[currentGriseDay] = 
            tokenHolderReward[currentGriseDay]
                        .add(stFee.mul(TRANSC_TOKEN_HOLDER_REWARD)
                        .div(REWARD_PRECISION_RATE));
            
            teamReward = stFee.mul(TEAM_SELL_TRANSC_REWARD)
                              .div(REWARD_PRECISION_RATE);
        }

        btFee = _calculateBuyTranscFee(amount);
        
        _balances[sender] =
        _balances[sender].sub(amount);

        _balances[recipient] =
        _balances[recipient].add(amount.sub(btFee).sub(stFee));

        teamReward += btFee.mul(TEAM_BUY_TRANS_REWARD)
                           .div(REWARD_PRECISION_RATE);
        
        _balances[TEAM_ADDRESS] = 
        _balances[TEAM_ADDRESS].add(teamReward.mul(90).div(100));

        _balances[DEVELOPER_ADDRESS] = 
        _balances[DEVELOPER_ADDRESS].add(teamReward.mul(10).div(100));

        // Burn Transction fee
        // We will mint token when user comes
        // to claim transction fee reward.
        _totalSupply =
        _totalSupply.sub(stFee.add(btFee).sub(teamReward));

        totalToken[currentGriseDay] = totalSupply().add(stakedToken);
        
        emit Transfer(
            sender,
            recipient,
            amount
        );
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            account != address(0x0)
        );
        
        _totalSupply =
        _totalSupply.add(amount);

        _balances[account] =
        _balances[account].add(amount);

        totalToken[currentGriseDay()] = totalSupply().add(stakedToken);
        
        emit Transfer(
            address(0x0),
            account,
            amount
        );
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:

     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            account != address(0x0)
        );
    
        _balances[account] =
        _balances[account].sub(amount);

        _totalSupply =
        _totalSupply.sub(amount);

        totalToken[currentGriseDay()] = _totalSupply.add(stakedToken);
        
        emit Transfer(
            account,
            address(0x0),
            amount
        );
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            owner != address(0x0)
        );

        require(
            spender != address(0x0)
        );

        _allowances[owner][spender] = amount;

        emit Approval(
            owner,
            spender,
            amount
        );
    }

    /**
     * @notice ability to define liquidity transformer contract
     * @dev this method renounce liquidtyGateKeeper access
     * @param _immutableGateKeeper contract address
     */
    function setLiquidtyGateKeeper(
        address _immutableGateKeeper
    )
        external
    {
        require(
            liquidtyGateKeeper == _msgSender(),
            'GRISE: Operation not allowed'
        );

        LIQUIDITY_GATEKEEPER = _immutableGateKeeper;
        liquidtyGateKeeper = address(0x0);
    }

    /**
     * @notice ability to define Staker contract
     * @dev this method renounce stakeGateKeeper access
     * @param _immutableGateKeeper contract address
     */
    function setStakeGateKeeper(
        address _immutableGateKeeper
    )
        external
    {
        require(
            stakeGateKeeper == _msgSender(),
            'GRISE: Operation not allowed'
        );

        STAKE_GATEKEEPER = _immutableGateKeeper;
        stakeGateKeeper = address(0x0);
    }

    /**
     * @notice ability to define vault contract
     * @dev this method renounce vaultGateKeeper access
     * @param _immutableGateKeeper contract address
     */
    function setVaultGateKeeper(
        address _immutableGateKeeper
    )
        external
    {
        require(
            vaultGateKeeper == _msgSender(),
            'GRISE: Operation not allowed'
        );

        VAULT_GATEKEEPER = _immutableGateKeeper;
        vaultGateKeeper = address(0x0);
    }

    modifier interfaceValidator() {
        require (
            _msgSender() == LIQUIDITY_GATEKEEPER ||
            _msgSender() == STAKE_GATEKEEPER ||
            _msgSender() == VAULT_GATEKEEPER,
            'GRISE: Operation not allowed'
        );
        _;
    }

    /**
     * @notice allows interfaceValidator to mint supply
     * @param _investorAddress address for minting GRISE tokens
     * @param _amount of tokens to mint for _investorAddress
     */
    function mintSupply(
        address _investorAddress,
        uint256 _amount
    )
        external
        interfaceValidator
    {       
        _mint(
            _investorAddress,
            _amount
        );
    }

    /**
     * @notice allows interfaceValidator to burn supply
     * @param _investorAddress address for minting GRISE tokens
     * @param _amount of tokens to mint for _investorAddress
     */
    function burnSupply(
        address _investorAddress,
        uint256 _amount
    )
        external
        interfaceValidator
    {
        _burn(
            _investorAddress,
            _amount
        );
    }
    
    function viewTokenHolderTranscReward() 
        external 
        view 
        returns (uint256 rewardAmount) 
    {
        
        uint256 _day = currentGriseDay();
        
        if( (balanceOf(_msgSender()) <= 0) ||
            isTranscFeeClaimed[_msgSender()][calculateGriseWeek(_day)] ||  
            calculateGriseWeek(_day) != currentGriseWeek())
        {
            rewardAmount = 0;
        }
        else
        {    
            uint256 calculationDay = _day.mod(GRISE_WEEK) > 0 ? 
                                    _day.sub(_day.mod(GRISE_WEEK)) :
                                    _day.sub(GRISE_WEEK);

            for (uint256 day = calculationDay; day < _day; day++)
            {
                rewardAmount += tokenHolderReward[day]
                                            .mul(_balances[_msgSender()])
                                            .div(totalToken[day]);
            }
        }
    }
    
    function claimTokenHolderTranscReward()
        external 
        returns (uint256 rewardAmount)
    {    
        uint256 _day = currentGriseDay();
        require( 
            balanceOf(_msgSender()) > 0,
            'GRISE - Token holder doesnot enough balance to claim reward'
        );
        
        require(
            (currentGriseDay().mod(GRISE_WEEK)) == 0,
            'GRISE - Transcation Reward window is not yeat open'
        );
        
        require(
            calculateGriseWeek(_day) == currentGriseWeek(),
            'GRISE - You are late/early to claim reward'
        );
        
        require( 
            !isTranscFeeClaimed[_msgSender()][currentGriseWeek()],
            'GRISE - Transcation Reward is already been claimed'
        );

        for (uint256 day = _day.sub(GRISE_WEEK); day < _day; day++)
        {
            rewardAmount += tokenHolderReward[day]
                                        .mul(_balances[_msgSender()])
                                        .div(totalToken[day]);
        }
                                        
        _mint(
            _msgSender(),
            rewardAmount
        );
        
        isTranscFeeClaimed[_msgSender()][currentGriseWeek()] = true;

        TranscFeeClaimed(_msgSender(), currentGriseWeek(), rewardAmount);
    }

    function setStaker(
        address _staker
    ) 
        external
    {    
        require(
            _msgSender() == STAKE_GATEKEEPER,
            'GRISE: Operation not allowed'
        );
        
        staker[_staker] = staker[_staker] + 1;
    }
    
    function resetStaker(
        address _staker
    ) 
        external
    {    
        require(
            _msgSender() == STAKE_GATEKEEPER,
            'GRISE: Operation not allowed'
        );
        
        if (staker[_staker] > 0)
        {
            staker[_staker] = staker[_staker] - 1;
        }
    }

    function updateStakedToken(
        uint256 _stakedToken
    ) 
        external
    {
        require(
            _msgSender() == STAKE_GATEKEEPER,
            'GRISE: Operation not allowed'
        );
            
        stakedToken = _stakedToken;
        totalToken[currentGriseDay()] = totalSupply().add(stakedToken);
    }

    function updateMedTermShares(
        uint256 _shares
    ) 
        external
    {    
        require(
            _msgSender() == STAKE_GATEKEEPER,
            'GRISE: Operation not allowed'
        );
        
        mediumTermShares = _shares;
    }

    function getTransFeeReward(
        uint256 _fromDay,
        uint256 _toDay
    ) 
        external 
        view 
        returns (uint256 rewardAmount)
    {
        require(
            _msgSender() == STAKE_GATEKEEPER,
            'GRISE: Operation not allowed'
        );

        for(uint256 day = _fromDay; day < _toDay; day++)
        {
            rewardAmount += stakerRewardPerShare[day];
        }
    }

    function getReservoirReward(
        uint256 _fromDay,
        uint256 _toDay
    ) 
        external
        view 
        returns (uint256 rewardAmount)
    {
        require(
            _msgSender() == STAKE_GATEKEEPER,
            'GRISE: Operation not allowed'
        );

        for(uint256 day = _fromDay; day < _toDay; day++)
        {
            rewardAmount += reservoirRewardPerShare[day];
        }
    }

    function getTokenHolderReward(
        uint256 _fromDay,
        uint256 _toDay
    ) 
        external
        view 
        returns (uint256 rewardAmount)
    {

        require(
            _msgSender() == STAKE_GATEKEEPER,
            'GRISE: Operation not allowed'
        );

        for(uint256 day = _fromDay; day < _toDay; day++)
        {
            rewardAmount += tokenHolderReward[day]
                            .mul(PRECISION_RATE)
                            .div(totalToken[day]);
        }
    }

    function timeToClaimWeeklyReward() 
        public
        view
        returns (uint256 _days)
    {
        _days = currentGriseDay().mod(GRISE_WEEK) > 0 ?
                    GRISE_WEEK - currentGriseDay().mod(GRISE_WEEK) :
                    0;
    }

    function timeToClaimMonthlyReward() 
        public 
        view 
        returns (uint256 _days)
    {
        _days = currentGriseDay().mod(GRISE_MONTH) > 0 ?
                    GRISE_MONTH - currentGriseDay().mod(GRISE_MONTH) :
                    0;
    }

    function balanceOfStaker(
        address account
    ) 
        external
        view
        returns (uint256)
    {
        return _balances[account];
    }

    function getEpocTime() 
        external
        view 
        returns (uint256)
    {
        return block.timestamp;
    }

    function getLaunchTime()
        external
        view
        returns (uint256)
    {
        return LAUNCH_TIME;
    }

    function getLPLaunchTime()
        external
        view
        returns (uint256)
    {
        return LP_LAUNCH_TIME;
    }

    function isStaker(
        address _staker
    ) 
        external
        view
        returns (bool status)
    {
        status = (staker[_staker] > 0) ? true : false;
    }
}