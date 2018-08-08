pragma solidity 0.4.17;

contract Ownable {
    address public owner;

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

}


contract TripCash is Ownable {

    uint256 public totalSupply = 5000000000 * 1 ether;


    string public constant name = "TripCash";
    string public constant symbol = "TASH";
    uint8 public constant decimals = 18;

    mapping (address => uint256) public balances; //Addresses map
    mapping (address => mapping(address => uint256)) public allowed;
    mapping (address => bool) public notransfer;


    uint256 public startPreICO = 1523840400; // preICO  start date
    uint256 public endPreICO = 1528675199; // preICO  finish date
    uint256 public startTime = 1529884800; // ICO  start date
    uint256 public endTime = 1532303999; // ICO  finish date


    address public constant ownerWallet = 0x9dA14C46f0182D850B12866AB0f3e397Fbd4FaC4; // Owner wallet address
    address public constant teamWallet1 = 0xe82F49A648FADaafd468E65a13C050434a4C4a6f ; // Team wallet address
    address public constant teamWallet2 = 0x16Eb7B7E232590787F1Fe3742acB1a1d0e43AF2A; // Team wallet address
    address public constant fundWallet = 0x949844acF5C722707d02A037D074cabe7474e0CB; // Fund wallet address
    address public constant frozenWallet2y = 0xAc77c90b37AFd80D2227f74971e7c3ad3e29D1fb; // For rest token frozen 2 year
    address public constant frozenWallet4y = 0x265B8e89DAbA5Bdc330E55cA826a9f2e0EFf0870; // For rest token frozen 4 year

    uint256 public constant ownerPercent = 10; // Owner percent token rate
    uint256 public constant teamPercent = 10; // Team percent token rate
    uint256 public constant bountyPercent = 10; // Bounty percent token rate

    bool public transferAllowed = false;
    bool public refundToken = false;

    /**
     * Token constructor
     *
     **/
    function TripCash() public {
        balances[owner] = totalSupply;
    }

    /**
     *  Modifier for checking token transfer
     */
    modifier canTransferToken(address _from) {
        if (_from != owner) {
            require(transferAllowed);
        }
        
        if (_from == teamWallet1) {
            require(now >= endTime + 15552000);
        }

        if (_from == teamWallet2) {
            require(now >= endTime + 31536000);
        }
        
        _;
    }

    /**
     *  Modifier for checking transfer allownes
     */
    modifier notAllowed(){
        require(!transferAllowed);
        _;
    }

    /**
     *  Modifier for checking ICO period
     */
    modifier saleIsOn() {
        require((now > startTime && now < endTime)||(now > startPreICO && now < endPreICO));
        _;
    }

    /**
     *  Modifier for checking refund allownes
     */

    modifier canRefundToken() {
        require(refundToken);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        uint256 tokenValue = balances[owner];

        transfer(_newOwner, tokenValue);
        owner = _newOwner;

        OwnershipTransferred(owner, _newOwner);

    }

    /**
     *
     *   Adding bonus tokens for bounty, team and owner needs. Should be used by DAPPs
     */
    function dappsBonusCalc(address _to, uint256 _value) onlyOwner saleIsOn() notAllowed public returns (bool) {

        require(_value != 0);
        transfer(_to, _value);
        notransfer[_to] = true;

        uint256 bountyTokenAmount = 0;
        uint256 ownerTokenAmount = 0;
        uint256 teamTokenAmount = 0;

        //calc bounty bonuses
        bountyTokenAmount = _value * bountyPercent / 60;

        //calc owner bonuses
        ownerTokenAmount = _value * ownerPercent / 60;

        //calc teamTokenAmount bonuses
        teamTokenAmount = _value * teamPercent / 60;
        
        transfer(ownerWallet, ownerTokenAmount);
        transfer(fundWallet, bountyTokenAmount);
        transfer(teamWallet1, teamTokenAmount);
        transfer(teamWallet2, teamTokenAmount);

        return true;
    }

    /**
     *
     *   Return number of tokens for address
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    /**
     * @dev Transfer tokens from one address to another
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transfer(address _to, uint256 _value) canTransferToken(msg.sender) public returns (bool){
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        if (notransfer[msg.sender] == true) {
            notransfer[msg.sender] = false;
        }

        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) canTransferToken(_from) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

        Transfer(_from, _to, _value);
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
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev function for rewarding token holders, who didn&#39;t transfer in 1 or 2 years
     * @param _holder token holders address
     */

    function rewarding(address _holder) public onlyOwner returns(uint){
        if(notransfer[_holder]==true){
            if(now >= endTime + 63072000){
                uint noTransfer2BonusYear = balances[_holder]*25 / 100;
                if (balances[fundWallet] >= noTransfer2BonusYear) {
                    balances[fundWallet] = balances[fundWallet] - noTransfer2BonusYear;
                    balances[_holder] = balances[_holder] + noTransfer2BonusYear;
                    assert(balances[_holder] >= noTransfer2BonusYear);
                    Transfer(fundWallet, _holder, noTransfer2BonusYear);
                    notransfer[_holder]=false;
                    return noTransfer2BonusYear;
                }
            } else if (now >= endTime + 31536000) {
                uint noTransferBonusYear = balances[_holder]*15 / 100;
                if (balances[fundWallet] >= noTransferBonusYear) {
                    balances[fundWallet] = balances[fundWallet] - noTransferBonusYear;
                    balances[_holder] = balances[_holder] + noTransferBonusYear;
                    assert(balances[_holder] >= noTransferBonusYear);
                    Transfer(fundWallet, _holder, noTransferBonusYear);
                    notransfer[_holder]=false;
                    return noTransferBonusYear;
                }
            }
        }
    }
    
    /**
     * Unsold and undistributed tokens will be vested (50% for 2 years, 50% for 4 years) 
     * to be allocated for the future development needs of the project; 
     * in case of high unexpected volatility of the token, 
     * part or all of the vested tokens can be burned to support the token&#39;s value.
     * /
    /**
     * function for after ICO burning tokens which was not bought
     * @param _value uint256 Amount of burning tokens
     */
    function burn(uint256 _value) onlyOwner public returns (bool){
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner] - _value;
        totalSupply = totalSupply - _value;
        Burn(burner, _value);
        return true;
    }
    
    /**
     *  Allownes refund
     */
    function changeRefundToken() public onlyOwner {
        require(now >= endTime);
        refundToken = true;
    }
    
     /**
     *  function for finishing ICO and allowed token transfer
     */
    function finishICO() public onlyOwner returns (bool) {
        uint frozenBalance = balances[msg.sender]/2;
        transfer(frozenWallet2y, frozenBalance);
        transfer(frozenWallet4y, balances[msg.sender]);
        transferAllowed = true;
        return true;
    }

    /**
     * return investor tokens and burning
     * 
     */
    function refund()  canRefundToken public returns (bool){
        uint256 _value = balances[msg.sender];
        balances[msg.sender] = 0;
        totalSupply = totalSupply - _value;
        Refund(msg.sender, _value);
        return true;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Refund(address indexed refuner, uint256 value);

}