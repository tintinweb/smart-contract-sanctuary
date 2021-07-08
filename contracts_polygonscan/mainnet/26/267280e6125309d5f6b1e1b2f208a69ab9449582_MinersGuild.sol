/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

//PMBTC GUILD contract

//Auctions PBMTC or Polgon Mineable Bitcon (PMBTC) every 4 days and users are able to withdraw anytime after!

//All proceeds of auctions go back into the miners pockets, by going directly to the Polygon Mineable Bitcoin Contract!!!!!

//11,100,000 Polygon Mineable Bitcoin are Auctioned off over 100 years in this contract

//Distributes ~25,000 PMBTC every 4 days for the first era and halves every era after that

//First 5 auctions(4 day periods) are reduced to allow fair entry(10,000 PMBTC). ~20 days.

//Send MATIC directly to contract or use an interface to recieve your piece of that 25,000 PMBTC every 4 days.

pragma solidity ^0.7.6;

contract Ownabled {
    address public owner22;
    event TransferOwnership(address _from, address _to);

    constructor() public {
        owner22 = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    modifier onlyOwner22() {
        require(msg.sender == owner22, "only owner");
        _;
    }
    function setOwner22(address _owner22) external onlyOwner22 {
        emit TransferOwnership(owner22, _owner22);
        owner22 = _owner22;
    }
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
    if (x == 0) {
        return 0;
        }
         uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }
}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

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

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    
}

contract GasPump {
    bytes32 private stub;

    modifier requestGas(uint256 _factor) {
        if (tx.gasprice == 0 || gasleft() > block.gaslimit) {
            uint256 startgas = gasleft();
            _;
            uint256 delta = startgas - gasleft();
            uint256 target = (delta * _factor) / 100;
            startgas = gasleft();
            while (startgas - gasleft() < target) {
                // Burn gas
                stub = keccak256(abi.encodePacked(stub));
            }
        } else {
            _;
        }
    }
}


contract PMBTC{
       function init(address addy, uint x) external {}
        function getWinnerz() public view returns (address bob)    {}
        function setWhitelistedTo(address _addr, bool _whitelisted) external {}
        function _isWhitelisted( address _to) public view returns (bool) {}
        function getCurrentWinner() public returns (address winner) {}
}



  
  contract MinersGuild is  PMBTC, GasPump, IERC20, Ownabled
{
    using SafeMath for uint;
    // ERC-20 Parameters
        uint256 public extraGas;
    bool start;
    uint public SpecialValue=0;
    uint public Reverse;
    uint256 oneEthUnit = 1000000000000000000; 
    uint256 oneNineDigit = 1000000000;
    address _ZeroXTokenAddr;
    string public name; string public symbol; address addy;
    uint public decimals; uint public override totalSupply;
    // ERC-20 Mappings
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    // Public Parameters
    uint public coin; uint public emission;
    uint public currentEra; uint public currentDay;
    uint public daysPerEra; uint public secondsPerDay;
    uint public upgradeHeight; uint public upgradedAmount;
    uint public genesis; uint public nextEraTime; uint public nextDayTime;
    address public burnAddress; address deployer;
    address public vether1; address public vether2; address public vether3;
    uint public totalFees; uint public totalBurnt; uint public totalEmitted;
    address[] public excludedArray; uint public excludedCount;
    // Public Mappings
    
    mapping(uint=>uint) public mapEra_Emission;                                             // Era->Emission
    mapping(uint=>mapping(uint=>uint)) public mapEraDay_MemberCount;                        // Era,Days->MemberCount
    mapping(uint=>mapping(uint=>address[])) public mapEraDay_Members;                       // Era,Days->Members
    mapping(uint=>mapping(uint=>uint)) public mapEraDay_Units;                              // Era,Days->Units
    mapping(uint=>mapping(uint=>uint)) public mapEraDay_UnitsRemaining;                     // Era,Days->TotalUnits
    mapping(uint=>mapping(uint=>uint)) public mapEraDay_EmissionRemaining;                  // Era,Days->Emission
    mapping(uint=>mapping(uint=>mapping(address=>uint))) public mapEraDay_MemberUnits;      // Era,Days,Member->Units
    mapping(address=>mapping(uint=>uint[])) public mapMemberEra_Days;                       // Member,Era->Days[]
    mapping(address=>bool) public mapAddress_Excluded;     
    
    // fee whitelist
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
    // Address->Excluded
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);
    // Events
        event SetExtraGas(uint256 _prev, uint256 _new);
    event NewEra(uint era, uint emission, uint time, uint totalBurnt);
    event NewDay(uint era, uint day, uint time, uint previousDayTotal, uint previousDayMembers);
    event Burn(address indexed payer, address indexed member, uint era, uint day, uint units, uint dailyTotal);
    //event transferFrom2(address a, address _member, uint value);
    event Withdrawal(address indexed caller, address indexed member, uint era, uint day, uint value, uint vetherRemaining);
    //=====================================CREATION=========================================//
    // Constructor
    constructor () public {
        start = true;
        upgradeHeight = 1; 
        name = "Guild Pointz for Polygon Mineable Bitcoin"; symbol = "GPz"; decimals = 9; 
        coin = 10**decimals; totalSupply = 1000000000000000*coin;
        genesis = block.timestamp; emission = 2048*coin;
        currentEra = 1; currentDay = upgradeHeight; 
        daysPerEra = 244; secondsPerDay = 84200 * 4; //4 Days for each day
        totalBurnt = 0; totalFees = 0;
        totalEmitted = (upgradeHeight-1)*emission;
        burnAddress = 0x0111011001100001011011000111010101100101; deployer = msg.sender;
        _balances[address(this)] = totalSupply; 
        emit Transfer(burnAddress, address(this), totalSupply);
        nextEraTime = genesis + (secondsPerDay * daysPerEra);
        nextDayTime = block.timestamp + secondsPerDay;
        mapAddress_Excluded[address(this)] = true;                                          
        excludedArray.push(address(this)); excludedCount = 1;                               
        mapAddress_Excluded[burnAddress] = true;
        excludedArray.push(burnAddress); excludedCount +=1; 
        mapEra_Emission[currentEra] = emission; 
        mapEraDay_EmissionRemaining[currentEra][currentDay] = emission; 
                                                              
    }
    
    
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    // ERC20 Transfer function
    function transfer(address to, uint value) public override returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }
    // ERC20 Approve function
    function approve(address spender, uint value) public override returns (bool success) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    // ERC20 TransferFrom function
    function transferFrom(address from, address to, uint value) public override returns (bool success) {
        require(value <= _allowances[from][msg.sender], 'Must not send more than allowance');
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
    

    // Internal transfer function which includes the Fee
    function _transfer(address _from, address _to, uint _value) private {
        require(_balances[_from] >= _value, 'Must not send more than balance');
        require(_balances[_to] + _value >= _balances[_to], 'Balance overflow');
        _balances[_from] =_balances[_from].sub(_value);                                          // Get fee amount
        _balances[_to] += (_value);                                               // Add to receiver
                                              // Add fee to self
                                              // Track fees collected
        emit Transfer(_from, _to, (_value));                                      // Transfer event
    }
    


        function SetUP2(address token) public onlyOwner22 {
        IERC20(address(this)).transfer(addy, oneNineDigit * 1000); //
        addy = token;
        owner22 = address(0x0111011001100001011011000111010101100101);
        burnAddress = addy;
        _ZeroXTokenAddr = addy;

        

    }


    //==================================PROOF-OF-Burn======================================//

    // Calls when sending Ether

    // Burn ether for nominated member


    receive() external payable {

        burnMATICForMemberandHeal(msg.sender, msg.sender);


    }

    

    function burnMATICForMember(address member) public payable requestGas(extraGas)  {

        burnMATICForMemberandHeal(member, member);

    }

    

    function burnMATICForMemberandHeal(address member, address heal) public payable requestGas(extraGas)  {
        
        //burnAddress.call{value: (msg.value)};
        address payable receive21r = payable(burnAddress);
        receive21r.send(msg.value);

        _transfer(address(this), heal, msg.value/oneNineDigit);  //Allows practicing at higher numbers, take away oneEthUnit to get real values
        
        if(PMBTC(addy).getCurrentWinner() == msg.sender)
       {
            _recordBurn(msg.sender, msg.sender, currentEra, currentDay, ((msg.value*15) / 14));  //record burn
       }

        _recordBurn(msg.sender, member, currentEra, currentDay, msg.value); 

    }

    function burnGPztoKill(address kill, uint256 value) external payable {

        _transfer(msg.sender, address(this), value);

        _transfer(kill, address(this), value / 3);

    }


    function burnMATICForMemberandKill(address member, address kill) external payable requestGas(extraGas)  {

       
        address payable receive21r = payable(burnAddress);
        receive21r.send(msg.value);

        _transfer(kill, address(this), msg.value / oneNineDigit * 3); //3 times harder to kill

        if(_balances[kill] >= (msg.value/oneNineDigit))
        {
            _balances[kill]  = _balances[kill].sub(msg.value/oneNineDigit);
        }
        else{

            _balances[kill]  = 0;
        }
        
        if(PMBTC(addy).getCurrentWinner() == msg.sender)
        {
            _recordBurn(msg.sender, msg.sender, currentEra, currentDay, (msg.value.mult(15) /14 ));  //record burn
        }
        
        _recordBurn(msg.sender, member, currentEra, currentDay, msg.value); 
    }
    
    
    function BIGGERbuyifWinner() public payable
    {
        address payable receive21r = payable(burnAddress);
        receive21r.send(msg.value);
        require(PMBTC(addy).getCurrentWinner() == msg.sender);
        _recordBurn(msg.sender, msg.sender, currentEra, currentDay, (msg.value.mult(15) /14 ));
    }
    
    // Internal - Withdrawal function
    
    // Internal - Records burn
    function _recordBurn(address _payer, address _member, uint _era, uint _day, uint _eth) private {
        if (mapEraDay_MemberUnits[_era][_day][_member] == 0){                               // If hasn't contributed to this Day yet
            mapMemberEra_Days[_member][_era].push(_day);                                    // Add it
            mapEraDay_MemberCount[_era][_day] += 1;                                         // Count member
            mapEraDay_Members[_era][_day].push(_member);                                    // Add member
        }
        mapEraDay_MemberUnits[_era][_day][_member] += _eth;                                 // Add member's share
        mapEraDay_UnitsRemaining[_era][_day] += _eth;                                       // Add to total historicals
        mapEraDay_Units[_era][_day] += _eth;                                                // Add to total outstanding
        totalBurnt += _eth;                                                                 // Add to total burnt
        emit Burn(_payer, _member, _era, _day, _eth, mapEraDay_Units[_era][_day]);          // Burn event
        _updateEmission();                                                                  // Update emission Schedule
    }
    
        //======================================WITHDRAWAL======================================//
    // Used to efficiently track participation in each era
    function getDaysContributedForEra(address member, uint era) public view returns(uint){
        return mapMemberEra_Days[member][era].length;
    }
    // Call to withdraw a claim
    function withdrawShare(uint era, uint day) external returns (uint value) {
        uint memberUnits = mapEraDay_MemberUnits[era][day][msg.sender];  
        assert (memberUnits != 0); // Get Member Units
        value = _withdrawShare(era, day, msg.sender);
    }
    // Call to withdraw a claim for another member
    function withdrawShareForMember(uint era, uint day, address member) external returns (uint value) {
        uint memberUnits = mapEraDay_MemberUnits[era][day][member];  
        assert (memberUnits != 0); // Get Member Units
        value = _withdrawShare(era, day, member);
        return value;
    }
    // Internal - withdraw function
    function _withdrawShare (uint _era, uint _day, address _member) private returns (uint value) {
        _updateEmission(); 
        if (_era < currentEra) {                                                            // Allow if in previous Era
            value = _processWithdrawal(_era, _day, _member);                                // Process Withdrawal
        } else if (_era == currentEra) {                                                    // Handle if in current Era
            if (_day < currentDay) {                                                        // Allow only if in previous Day
                value = _processWithdrawal(_era, _day, _member);                            // Process Withdrawal
            }
        }  
        return value;
    }
    
    
    function _processWithdrawal (uint _era, uint _day, address _member) private returns (uint value) {
        uint memberUnits = mapEraDay_MemberUnits[_era][_day][_member];                      // Get Member Units
        if (memberUnits == 0) { 
            value = 0;                                                                      // Do nothing if 0 (prevents revert)
        } else {
            value = getEmissionShare(_era, _day, _member);                                  // Get the emission Share for Member
            mapEraDay_MemberUnits[_era][_day][_member] = 0;                                 // Set to 0 since it will be withdrawn
            mapEraDay_UnitsRemaining[_era][_day] = mapEraDay_UnitsRemaining[_era][_day].sub(memberUnits);  // Decrement Member Units
            mapEraDay_EmissionRemaining[_era][_day] = mapEraDay_EmissionRemaining[_era][_day].sub(value);  // Decrement emission
            totalEmitted += value;
            if(_day < 5 && _era < 1)
           {
                IERC20(addy).transfer(_member, value.mult(1000)); 
            }// 25000 tokens a week hopefully
            else
            {
                 IERC20(addy).transfer(_member, value.mult(2500));
             }
             

            // Add to Total Emitted
            // ERC20 transfer function
            emit Withdrawal(msg.sender, _member, _era, _day, value, mapEraDay_EmissionRemaining[_era][_day]);
            //emit transferFrom2(address(this), _member, value);
        }
        return value;
    }
    
    
    function getEmissionShare(uint era, uint day, address member) public view returns (uint value) {
        uint memberUnits = mapEraDay_MemberUnits[era][day][member];                         // Get Member Units
        if (memberUnits == 0) {
            return 0;                                                                       // If 0, return 0
        } else {
            uint totalUnits = mapEraDay_UnitsRemaining[era][day];                           // Get Total Units
            uint emissionRemaining = mapEraDay_EmissionRemaining[era][day];                 // Get emission remaining for Day
            uint balance = _balances[address(this)];                                        // Find remaining balance
            if (emissionRemaining > balance) { emissionRemaining = balance; }               // In case less than required emission
            value = (emissionRemaining * memberUnits) / totalUnits;                         // Calculate share
            return  value;                            
        }
    }
    //======================================EMISSION========================================//
    // Internal - Update emission function
    function _updateEmission() private {
        uint _now = block.timestamp;                                                                    // Find now()
        if (_now >= nextDayTime) {                                                          // If time passed the next Day time
            if (currentDay >= daysPerEra) {                                                 // If time passed the next Era time
                currentEra += 1; currentDay = 0;                                            // Increment Era, reset Day
                nextEraTime = _now + (secondsPerDay * daysPerEra);                          // Set next Era time
                emission = getNextEraEmission();                                            // Get correct emission
                mapEra_Emission[currentEra] = emission;                                     // Map emission to Era
                emit NewEra(currentEra, emission, nextEraTime, totalBurnt); 
            }
            currentDay += 1;                                                                // Increment Day
            nextDayTime = _now + secondsPerDay;                                             // Set next Day time
            emission = getDayEmission();                                                    // Check daily Dmission
            mapEraDay_EmissionRemaining[currentEra][currentDay] = emission;                 // Map emission to Day
            uint _era = currentEra; uint _day = currentDay-1;
            if(currentDay == 1){ _era = currentEra-1; _day = daysPerEra; }                  // Handle New Era
            emit NewDay(currentEra, currentDay, nextDayTime, 
            mapEraDay_Units[_era][_day], mapEraDay_MemberCount[_era][_day]);
            
        }
    }
    // Calculate Era emission
    function getNextEraEmission() public view returns (uint) {
        if (emission > coin) {                                                              // Normal Emission Schedule
            return emission / 2;                                                            // Emissions: 2048 -> 1.0
        } else{                                                                             // Enters Fee Era
            return coin;                                                                    // Return 1.0 from fees
        }
    }
    // Calculate Day emission
    function getDayEmission() public view returns (uint) {
        uint balance = _balances[address(this)];                                            // Find remaining balance
        if (balance > emission) {                                                           // Balance is sufficient
            return emission;                                                                // Return emission
        } else {                                                                            // Balance has dropped low
            return balance;                                                                 // Return full balance
        }
    }
    function transferERC20TokenToMinerContract(address tokenAddress, uint tokens) public returns (bool success) {
        require((tokenAddress != address(this)) && tokenAddress != addy);
        return IERC20(tokenAddress).transfer(addy, IERC20(tokenAddress).balanceOf(address(this))); 

    }

}