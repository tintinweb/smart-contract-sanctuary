pragma solidity ^0.4.13;

contract IFinancialStrategy{

    enum State { Active, Refunding, Closed }
    State public state = State.Active;

    event Deposited(address indexed beneficiary, uint256 weiAmount);
    event Receive(address indexed beneficiary, uint256 weiAmount);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Started();
    event Closed();
    event RefundsEnabled();
    function freeCash() view public returns(uint256);
    function deposit(address _beneficiary) external payable;
    function refund(address _investor) external;
    function setup(uint8 _state, bytes32[] _params) external;
    function getBeneficiaryCash() external;
    function getPartnerCash(uint8 _user, address _msgsender) external;
}

contract IRightAndRoles {
    address[][] public wallets;
    mapping(address => uint16) public roles;

    event WalletChanged(address indexed newWallet, address indexed oldWallet, uint8 indexed role);
    event CloneChanged(address indexed wallet, uint8 indexed role, bool indexed mod);

    function changeWallet(address _wallet, uint8 _role) external;
    function setManagerPowerful(bool _mode) external;
    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool);
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

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
        emit Transfer(msg.sender, _to, _value);
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

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
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
    function allowance(address _owner, address _spender) public view returns (uint256) {
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
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract IAllocation {
    function addShare(address _beneficiary, uint256 _proportion, uint256 _percenForFirstPart) external;
}

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
        uint256 c = a / b;
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
    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b>=a) return 0;
        return a - b;
    }
}

contract ICreator{
    function createAllocation(IToken _token, uint256 _unlockPart1, uint256 _unlockPart2) external returns (IAllocation);
    function createFinancialStrategy() external returns(IFinancialStrategy);
    function getRightAndRoles() external returns(IRightAndRoles);
}

contract RightAndRoles is IRightAndRoles {
    bool managerPowerful = true;

    function RightAndRoles(address[] _roles) public {
        uint8 len = uint8(_roles.length);
        require(len > 0&&len <16);
        wallets.length = len;

        for(uint8 i = 0; i < len; i++){
            wallets[i].push(_roles[i]);
            roles[_roles[i]] += uint16(2)**i;
            emit WalletChanged(_roles[i], address(0),i);
        }
    }

    function changeClons(address _clon, uint8 _role, bool _mod) external {
        require(wallets[_role][0] == msg.sender&&_clon != msg.sender);
        emit CloneChanged(_clon,_role,_mod);
        uint16 roleMask = uint16(2)**_role;
        if(_mod){
            require(roles[_clon]&roleMask == 0);
            wallets[_role].push(_clon);
        }else{
            address[] storage tmp = wallets[_role];
            uint8 i = 1;
            for(i; i < tmp.length; i++){
                if(tmp[i] == _clon) break;
            }
            require(i > tmp.length);
            tmp[i] = tmp[tmp.length];
            delete tmp[tmp.length];
        }
        roles[_clon] = _mod?roles[_clon]|roleMask:roles[_clon]&~roleMask;
    }

    // Change the address for the specified role.
    // Available to any wallet owner except the observer.
    // Available to the manager until the round is initialized.
    // The Observer&#39;s wallet or his own manager can change at any time.
    // @ Do I have to use the function      no
    // @ When it is possible to call        depend...
    // @ When it is launched automatically  -
    // @ Who can call the function          staff (all 7+ roles)
    function changeWallet(address _wallet, uint8 _role) external {
        require(wallets[_role][0] == msg.sender || wallets[0][0] == msg.sender || (wallets[1][0] == msg.sender && managerPowerful /* && _role != 0*/));
        emit WalletChanged(wallets[_role][0],_wallet,_role);
        uint16 roleMask = uint16(2)**_role;
        address[] storage tmp = wallets[_role];
        for(uint8 i = 0; i < tmp.length; i++){
            roles[tmp[i]] = roles[tmp[i]]&~roleMask;
        }
        delete  wallets[_role];
        tmp.push(_wallet);
        roles[_wallet] = roles[_wallet]|roleMask;
    }

    function setManagerPowerful(bool _mode) external {
        require(wallets[0][0] == msg.sender);
        managerPowerful = _mode;
    }

    function onlyRoles(address _sender, uint16 _roleMask) view external returns(bool) {
        return roles[_sender]&_roleMask != 0;
    }

    function getMainWallets() view external returns(address[]){
        address[] memory _wallets = new address[](wallets.length);
        for(uint8 i = 0; i<wallets.length; i++){
            _wallets[i] = wallets[i][0];
        }
        return _wallets;
    }

    function getCloneWallets(uint8 _role) view external returns(address[]){
        return wallets[_role];
    }
}

contract Creator is ICreator{
    IRightAndRoles public rightAndRoles;
    address[] tmp1;

    function Creator() public{
        address[] memory tmp = new address[](8);
        //Crowdsale.
        tmp[0] = address(this);
        //manager
        tmp[1] = msg.sender;
        //beneficiary
        tmp[2] = 0xd228DF77aF3df82cB7580D48FD0b33Fe43A70F0e;
        // Accountant
        // Receives all the tokens for non-ETH investors (when finalizing Round1 & Round2)
        tmp[3] = 0xcDd417d7f260B08CD10a3810321dF7A40D65bA40;
        // Observer
        // Has only the right to call paymentsInOtherCurrency (please read the document)
        tmp[4] = 0x8a91aC199440Da0B45B2E278f3fE616b1bCcC494;
        // Bounty - 2% tokens
        tmp[5] = 0x903b15589855B8c944e9b865A5814D656dA16544;
        // Company - 10% tokens
        tmp[6] = 0xcA2d7C0147fCE138736981fb1Aa273d89cC9A3BF;
        // Team - 11% tokens, freeze 1 year
        tmp[7] = 0x7767B19420c89Bb79908820f4a5E55dc65ca7658;
        rightAndRoles = new RightAndRoles(tmp);
    }

    function createAllocation(IToken _token, uint256 _unlockPart1, uint256 _unlockPart2) external returns (IAllocation) {
        Allocation allocation = new Allocation(rightAndRoles,ERC20Basic(_token),_unlockPart1,_unlockPart2);
        return allocation;
    }

    function createFinancialStrategy() external returns(IFinancialStrategy) {
        return new FinancialStrategy(rightAndRoles);
    }

    function getRightAndRoles() external returns(IRightAndRoles){
        rightAndRoles.changeWallet(msg.sender,0);
        return rightAndRoles;
    }
}

contract IToken{
    function setUnpausedWallet(address _wallet, bool mode) public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function totalSupply() public view returns (uint256);
    function setPause(bool mode) public;
    function setMigrationAgent(address _migrationAgent) public;
    function migrateAll(address[] _holders) public;
    function burn(address _beneficiary, uint256 _value) public;
    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount);
    function defrostDate(address _beneficiary) public view returns (uint256 Date);
    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public;
}

contract GuidedByRoles {
    IRightAndRoles public rightAndRoles;
    function GuidedByRoles(IRightAndRoles _rightAndRoles) public {
        rightAndRoles = _rightAndRoles;
    }
}

contract Pausable is GuidedByRoles {

    mapping (address => bool) public unpausedWallet;

    event Pause();
    event Unpause();

    bool public paused = true;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused(address _to) {
        require(!paused||unpausedWallet[msg.sender]||unpausedWallet[_to]);
        _;
    }

    function onlyAdmin() internal view {
        require(rightAndRoles.onlyRoles(msg.sender,3));
    }

    // Add a wallet ignoring the "Exchange pause". Available to the owner of the contract.
    function setUnpausedWallet(address _wallet, bool mode) public {
        onlyAdmin();
        unpausedWallet[_wallet] = mode;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function setPause(bool mode)  public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        if (!paused && mode) {
            paused = true;
            emit Pause();
        }else
        if (paused && !mode) {
            paused = false;
            emit Unpause();
        }
    }

}

contract Allocation is GuidedByRoles, IAllocation {
    using SafeMath for uint256;

    struct Share {
        uint256 proportion;
        uint256 forPart;
    }

    // How many days to freeze from the moment of finalizing ICO
    uint256 public unlockPart1;
    uint256 public unlockPart2;
    uint256 public totalShare;

    mapping(address => Share) public shares;

    ERC20Basic public token;

    // The contract takes the ERC20 coin address from which this contract will work and from the
    // owner (Team wallet) who owns the funds.
    function Allocation(IRightAndRoles _rightAndRoles,ERC20Basic _token, uint256 _unlockPart1, uint256 _unlockPart2) GuidedByRoles(_rightAndRoles) public{
        unlockPart1 = _unlockPart1;
        unlockPart2 = _unlockPart2;
        token = _token;
    }

    function addShare(address _beneficiary, uint256 _proportion, uint256 _percenForFirstPart) external {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        shares[_beneficiary] = Share(shares[_beneficiary].proportion.add(_proportion),_percenForFirstPart);
        totalShare = totalShare.add(_proportion);
    }

    //    function unlock() external {
    //        unlockFor(msg.sender);
    //    }

    // If the time of freezing expired will return the funds to the owner.
    function unlockFor(address _owner) public {
        require(now >= unlockPart1);
        uint256 share = shares[_owner].proportion;
        if (now < unlockPart2) {
            share = share.mul(shares[_owner].forPart)/100;
            shares[_owner].forPart = 0;
        }
        if (share > 0) {
            uint256 unlockedToken = token.balanceOf(this).mul(share).div(totalShare);
            shares[_owner].proportion = shares[_owner].proportion.sub(share);
            totalShare = totalShare.sub(share);
            token.transfer(_owner,unlockedToken);
        }
    }
}

contract BurnableToken is BasicToken, GuidedByRoles {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(address _beneficiary, uint256 _value) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(_value <= balances[_beneficiary]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_beneficiary] = balances[_beneficiary].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_beneficiary, _value);
        emit Transfer(_beneficiary, address(0), _value);
    }
}

contract FinancialStrategy is IFinancialStrategy, GuidedByRoles{
    using SafeMath for uint256;

    uint8 public step;

    mapping (uint8 => mapping (address => uint256)) public deposited;

                             // Partner 0   Partner 1    Partner 2
    uint256[0] public percent;
    uint256[0] public cap; // QUINTILLIONS
    uint256[0] public debt;
    uint256[0] public total;                                 // QUINTILLIONS
    uint256[0] public took;
    uint256[0] public ready;

    address[0] public wallets;

    uint256 public benTook=0;
    uint256 public benReady=0;
    uint256 public newCash=0;
    uint256 public cashHistory=0;

    address public benWallet=0;

    modifier canGetCash(){
        require(state == State.Closed);
        _;
    }

    function FinancialStrategy(IRightAndRoles _rightAndRoles) GuidedByRoles(_rightAndRoles) public {
        emit Started();
    }

    function balance() external view returns(uint256){
        return address(this).balance;
    }

    
    function deposit(address _investor) external payable {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(state == State.Active);
        deposited[step][_investor] = deposited[step][_investor].add(msg.value);
        newCash = newCash.add(msg.value);
        cashHistory += msg.value;
        emit Deposited(_investor,msg.value);
    }


    // 0 - destruct
    // 1 - close
    // 2 - restart
    // 3 - refund
    // 4 - calc
    // 5 - update Exchange                                                                      
    function setup(uint8 _state, bytes32[] _params) external {
        require(rightAndRoles.onlyRoles(msg.sender,1));

        if (_state == 0)  {
            require(_params.length == 1);
            // call from Crowdsale.distructVault(true) for exit
            // arg1 - nothing
            // arg2 - nothing
            selfdestruct(address(_params[0]));

        }
        else if (_state == 1 ) {
            require(_params.length == 0);
            // Call from Crowdsale.finalization()
            //   [1] - successfull round (goalReach)
            //   [3] - failed round (not enough money)
            // arg1 = weiTotalRaised();
            // arg2 = nothing;
        
            require(state == State.Active);
            //internalCalc(_arg1);
            state = State.Closed;
            emit Closed();
        
        }
        else if (_state == 2) {
            require(_params.length == 0);
            // Call from Crowdsale.initialization()
            // arg1 = weiTotalRaised();
            // arg2 = nothing;
            require(state == State.Closed);
            require(address(this).balance == 0);
            state = State.Active;
            step++;
            emit Started();
        
        }
        else if (_state == 3 ) {
            require(_params.length == 0);
            require(state == State.Active);
            state = State.Refunding;
            emit RefundsEnabled();
        }
        else if (_state == 4) {
            require(_params.length == 2);
            //onlyPartnersOrAdmin(address(_params[1]));
            internalCalc(uint256(_params[0]));
        }
        else if (_state == 5) {
            // arg1 = old ETH/USD (exchange)
            // arg2 = new ETH/USD (_ETHUSD)
            require(_params.length == 2);
            for (uint8 user=0; user<cap.length; user++) cap[user]=cap[user].mul(uint256(_params[0])).div(uint256(_params[1]));
        }

    }

    function freeCash() view public returns(uint256){
        return newCash+benReady;
    }

    function internalCalc(uint256 _allValue) internal {

        uint256 free=newCash+benReady;
        uint256 common=0;
        uint256 prcSum=0;
        uint256 plan=0;
        uint8[] memory indexes = new uint8[](percent.length);
        uint8 count = 0;

        if (free==0) return;

        uint8 i;

        for (i =0; i <percent.length; i++) {
            plan=_allValue*percent[i]/100;

            if(cap[i] != 0 && plan > cap[i]) plan = cap[i];

            if (total[i] >= plan) {
                debt[i]=0;
                continue;
            }

            plan -= total[i];
            debt[i] = plan;
            common += plan;
            indexes[count++] = i;
            prcSum += percent[i];
        }
        if(common > free){
            benReady = 0;
            uint8 j = 0;
            while (j < count){
                i = indexes[j++];
                plan = free*percent[i]/prcSum;
                if(plan + total[i] <= cap[i] || cap[i] ==0){
                    debt[i] = plan;
                    continue;
                }
                debt[i] = cap[i] - total[i]; //&#39;total&#39; is always less than &#39;cap&#39;
                free -= debt[i];
                prcSum -= percent[i];
                indexes[j-1] = indexes[--count];
                j = 0;
            }
        }
        common = 0;
        for(i = 0; i < debt.length; i++){
            total[i] += debt[i];
            ready[i] += debt[i];
            common += ready[i];
        }
        benReady = address(this).balance - common;
        newCash = 0;
    }

    function refund(address _investor) external {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[step][_investor];
        require(depositedValue > 0);
        deposited[step][_investor] = 0;
        _investor.transfer(depositedValue);
        emit Refunded(_investor, depositedValue);
    }

    // Call from Crowdsale:
    function getBeneficiaryCash() external canGetCash {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        address _beneficiary = rightAndRoles.wallets(2,0);
        uint256 move=benReady;
        benWallet=_beneficiary;
        if (move == 0) return;

        emit Receive(_beneficiary, move);
        benReady = 0;
        benTook += move;
        
        _beneficiary.transfer(move);
    
    }


    // Call from Crowdsale:
    function getPartnerCash(uint8 _user, address _msgsender) external canGetCash {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(_user<wallets.length);

        onlyPartnersOrAdmin(_msgsender);

        uint256 move=ready[_user];
        if (move==0) return;

        emit Receive(wallets[_user], move);
        ready[_user]=0;
        took[_user]+=move;

        wallets[_user].transfer(move);
    
    }

    function onlyPartnersOrAdmin(address _sender) internal view {
        if (!rightAndRoles.onlyRoles(_sender,65535)) {
            for (uint8 i=0; i<wallets.length; i++) {
                if (wallets[i]==_sender) break;
            }
            if (i>=wallets.length) {
                revert();
            }
        }
    }
}

contract MigratableToken is BasicToken,GuidedByRoles {

    uint256 public totalMigrated;
    address public migrationAgent;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    function setMigrationAgent(address _migrationAgent) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        require(totalMigrated == 0);
        migrationAgent = _migrationAgent;
    }


    function migrateInternal(address _holder) internal{
        require(migrationAgent != 0x0);

        uint256 value = balances[_holder];
        balances[_holder] = 0;

        totalSupply_ = totalSupply_.sub(value);
        totalMigrated = totalMigrated.add(value);

        MigrationAgent(migrationAgent).migrateFrom(_holder, value);
        emit Migrate(_holder,migrationAgent,value);
    }

    function migrateAll(address[] _holders) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        for(uint i = 0; i < _holders.length; i++){
            migrateInternal(_holders[i]);
        }
    }

    // Reissue your tokens.
    function migrate() public
    {
        require(balances[msg.sender] > 0);
        migrateInternal(msg.sender);
    }

}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

contract FreezingToken is PausableToken {
    struct freeze {
    uint256 amount;
    uint256 when;
    }


    mapping (address => freeze) freezedTokens;

    function freezedTokenOf(address _beneficiary) public view returns (uint256 amount){
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.amount;
    }

    function defrostDate(address _beneficiary) public view returns (uint256 Date) {
        freeze storage _freeze = freezedTokens[_beneficiary];
        if(_freeze.when < now) return 0;
        return _freeze.when;
    }

    function freezeTokens(address _beneficiary, uint256 _amount, uint256 _when) public {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        freeze storage _freeze = freezedTokens[_beneficiary];
        _freeze.amount = _amount;
        _freeze.when = _when;
    }

    function masFreezedTokens(address[] _beneficiary, uint256[] _amount, uint256[] _when) public {
        onlyAdmin();
        require(_beneficiary.length == _amount.length && _beneficiary.length == _when.length);
        for(uint16 i = 0; i < _beneficiary.length; i++){
            freeze storage _freeze = freezedTokens[_beneficiary[i]];
            _freeze.amount = _amount[i];
            _freeze.when = _when[i];
        }
    }


    function transferAndFreeze(address _to, uint256 _value, uint256 _when) external {
        require(unpausedWallet[msg.sender]);
        require(freezedTokenOf(_to) == 0);
        if(_when > 0){
            freeze storage _freeze = freezedTokens[_to];
            _freeze.amount = _value;
            _freeze.when = _when;
        }
        transfer(_to,_value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= freezedTokenOf(msg.sender).add(_value));
        return super.transfer(_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf(_from) >= freezedTokenOf(_from).add(_value));
        return super.transferFrom( _from,_to,_value);
    }
}

contract MintableToken is StandardToken, GuidedByRoles {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public returns (bool) {
        require(rightAndRoles.onlyRoles(msg.sender,1));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}

contract Token is IToken, FreezingToken, MintableToken, MigratableToken, BurnableToken{
    function Token(IRightAndRoles _rightAndRoles) GuidedByRoles(_rightAndRoles) public {}
    string public constant name = "Ale Coin";
    string public constant symbol = "ALE";
    uint8 public constant decimals = 18;
}

contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}