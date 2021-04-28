/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.6.12;
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}
contract ERC20 {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
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

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);                  // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

    contract TEST {
    string public name;     // Token name
    address public manager; // Contract owner address
    string public symbol;   // Token symbol
    uint256 public decimals = 18;               // Token decimals
    uint256 private LPTokenDecimals = 18;       // Liquidity provider (LP) token decimals
    uint256 public genesisBlock = block.number; // Block number of the contract creation
    uint256 public PERASupply = 10000000 * 10 ** uint256(decimals); // Initial PERA supply
    uint256 public totalSupply;

    // Initial rate for holder reward distribution coefficient (transferRate), used for rebasing holders' balances
    uint256 private constant transferRateInitial = ~uint240(0);
    uint256 public transferRate = (transferRateInitial - (transferRateInitial % PERASupply))/PERASupply;
    // Number of blocks within a day (approximately 28,800 blocks for Binance Smart Chain & 6500 blocks for Ethereum Network)
    uint private BlockSizeForTC = 28800;
    // Number of blocks within a week
    uint private oneWeekasBlock = BlockSizeForTC * 7;
    // Number of blocks within 10 years (PERA emission stops after 10 years)
    uint private tenYearsasBlock = oneWeekasBlock * 520;

    // Daily PERA emission reward for trading competition (TC) reward pool
    uint public dailyRewardForTC = 2800 * 10 ** uint256(decimals);
    // Contract deployer can set the reward multiplier (see function updateTCMultiplier)
    // Initial value, 20, sets the trading competition emission reward to 5600 PERA/day
    uint256 public TCRewardMultiplier = 20;
    // Number of users with the highest daily volume who are eligible to win the daily trading competition
    uint8 private totalTCwinners = 10;
    // Contract deployer can set the minimum PERA transaction that is required for the trading competition within the range 10-1000
    // Initial value = min 100 PERA transaction is required  (see function updateminTCamount)
    uint256 public minTCamount = 100 * 10 ** decimals;
    // Record of total transaction fee rewards collected for the trading competition reward pool
    mapping (uint256 => uint256) public totalRewardforTC;

    // Total number of LP tokens staked in the contract
    uint public totalStakedLP = 0;
    // Contract releases 0.5 PERA/block as LP token staker reward
    uint public blockRewardLP = 5 * 10 ** uint256(decimals);
    // Contract deployer can set the reward multiplier within the range 1-10 (see function updateLPMultiplier)
    // Initial value, 20, sets the LP token staker emission reward to 0.5 PERA/block
    uint256 public LPRewardMultiplier = 20;
    // Initial rate for LP token staker reward distribution coefficient (LPRate)
    uint256 public LPRate = 0;
    // Transaction fee rewards collected specifically for LP token stakers (0.75% of each PERA transaction)
    uint256 public FeeRewPoolLP = 0;
    // Smart contract address of the LP token (should be set by the contract owner, see function addLPToken)
    address lpTokenAddress;
    // Record of staked LP token amount for a given address
    mapping (address => uint256) private userLPamount;
    // Last block number that PERA distribution occurs for LP token stakers
    uint256 private lastRewardBlock = 0;

    // PERA smart contract applies a 2% transaction fee on each on-chain PERA transaction
    uint private tradingCompFee = 50; // Transaction fee rate for trading competition reward pool (0.50% of each PERA transaction)
    uint private holderFee = 75;      // Transaction fee rate for holder rewards (0.75% of each PERA transaction)
    uint private liqproviderFee = 75; // Transaction fee rate for LP token staker rewards (0.75% of each PERA transaction)

    mapping (address => bool) public isNonTaxable;

    address[] public _excluded;
    mapping (address => uint256) private userbalanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    using SafeMath for uint;

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol

    ) public {
        initialSupply = PERASupply.mul(transferRate);
        tokenName = "TEST";
        tokenSymbol = "TEST";
        manager = msg.sender;
        userbalanceOf[msg.sender] = initialSupply;
        totalSupply =  PERASupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    // Function can only be used by the contract owner
    // Used for excluding an address as a holder
    // Excluded addresses do not receive holder rewards (0.75% of each on-chain PERA transaction)
    // For the holder rewards to be distributed properly, contract owner should follow these steps after the contract deployment:
    // 1- Exclude the token smart contract address
    // 2- Exclude the contract owner address
    // 3- Exclude the AMM-exchange router contract address
    // 4- Provide the initial liquidity to an AMM-exchange
    // 5- Exclude the pool address where the initial liquidity is provided
    function excludeAccount(address account) external {
        require(msg.sender == manager);
        require(!_isExcluded(account));
        _excluded.push(account);
        userbalanceOf[account] = userbalanceOf[account].div(transferRate);
    }

    // Function can only be used by the contract owner
    // Used for removing an address from the excluded holders list
    function includeAccount(address account) external {
    require(msg.sender == manager);
    require(_isExcluded(account));
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();
                userbalanceOf[account] = userbalanceOf[account].mul(transferRate);
                break;
            }
        }
    }

    // Function for checking if a given address is in the excluded holders list
    function _isExcluded(address _addr) view public returns (bool) {
        for(uint i=0; i < _excluded.length; i++){
            if(_addr == _excluded[i]){
                return  true;
            }
        }
    return false;
    }

    // Function is used to calculate how many PERA tokens is held by the users who are in the excluded holders list
    function _removeExcludedAmounts() view public returns (uint) {
     uint totalRemoved = 0;
         for(uint i=0; i < _excluded.length; i++){
            totalRemoved += userbalanceOf[_excluded[i]];
         }
    return totalRemoved;
    }

    function excludeFromTax(address _account, uint256 _checkTax) external {
        require(msg.sender == manager);
        if(_checkTax == 0){
            isNonTaxable[_account] = false;
        }else{
            isNonTaxable[_account] = true;
        }
    }

    // Function can only be used by the contract owner
    // It is used to set the reward multiplier for LP token stakers
    // Initial value is set to 20 (0,5 PERA/block)
    function updateLPMultiplier(uint256 newLPMultiplier) external {
        require(msg.sender == manager);
        require(newLPMultiplier >= 0 && newLPMultiplier <= 200, 'Multiplier is out of the acceptable range!');
        LPRewardMultiplier = newLPMultiplier;
    }

    // Function can only be used by the contract owner
    // It is used to set the reward multiplier for the trading competition reward pool
    // Initial value is set to 20 (5600 PERA/day)
    function updateTCMultiplier(uint256 newTCMultiplier) external {
        require(msg.sender == manager);
        require(newTCMultiplier >= 0 && newTCMultiplier <= 100, 'Multiplier is out of the acceptable range!');
        TCRewardMultiplier = newTCMultiplier;
    }

    // Function can only be used by the contract owner
    // It is used to set the minimum PERA transaction required for the trading competition
    // Initial value is set to 100
    function updateminTCamount(uint256 newminTCamount) external {
        require(msg.sender == manager);
        require(newminTCamount >= (10 * 10 ** decimals)  && newminTCamount <= (1000 * 10 ** decimals), 'Amount is out of the acceptable range!');
        minTCamount = newminTCamount;
    }

    // Function can only be used by the contract owner
    // It is used to add the contract address of the LP token
    function addLPToken(address _addr)  external {
        require(msg.sender == manager);
        lpTokenAddress = _addr;
    }

    // User balances are represented in two different ways:
    // 1- If the address is excluded then the balance remains as it is
    // 2- If the address is not excluded then the balance is weighted with the lastly updated value of the transferRate (see function balanceRebalance)
    function balanceOf(address _addr) public view returns (uint256) {
      if (_isExcluded(_addr)){
          return userbalanceOf[_addr];
      } else{
          return balanceRebalance(userbalanceOf[_addr]);
      }
    }

    function balanceRebalance(uint256 userBalances) private view returns(uint256) {
      return userBalances.div(transferRate);
    }

    function transferOwnership(address newOwner) public{
        require(msg.sender == manager);
        if (newOwner != address(0)) {
            manager = newOwner;
        }
    }

    // Checks if a given address is the contract owner
    function isManager(address _addr) view private returns(bool) {
        bool isManagerCheck = false;
        if(_addr == manager){
            isManagerCheck = true;
        }
    return  isManagerCheck;
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));

        // Checks if the transaction sender is an excluded address
        // Balance checks should be weighted with the lastly updated value of the transferRate for non-excluded addresses
        if(!_isExcluded(_from)){
            require(userbalanceOf[_from].div(transferRate) >= _value);
            require(userbalanceOf[_to].div(transferRate) + _value >= userbalanceOf[_to].div(transferRate));
        }else{
            require(userbalanceOf[_from] >= _value);
            require(userbalanceOf[_to] + _value >= userbalanceOf[_to]);
        }

        // If the transaction sender is the contract owner or the contract itself then no fee is applied on the transaction
        uint256 tenthousandthofamonut = _value.div(10000);
        if(isNonTaxable[_from] || isNonTaxable[_to]){
            tenthousandthofamonut = 0;
        }

        // How many days have passed since the contract creation
        uint256 _bnum = (block.number - genesisBlock)/BlockSizeForTC;
        // 0.5% of the transacted amount is added to the daily trading competition reward pool
        totalRewardforTC[_bnum]  +=  uint(tenthousandthofamonut.mul(tradingCompFee));
        // 0.75% of the transacted amount is added to the LP token staker rewards
        // If there is no LP token staked in the contract, then the amount is set to zero
        if(totalStakedLP != 0){
            FeeRewPoolLP  +=  uint(tenthousandthofamonut.mul(liqproviderFee));
        }

        // Total amount of tokens taken out as the transaction fee (2% of the transacted amount)
        uint totalOut = uint(tenthousandthofamonut.mul(tradingCompFee)) + uint(tenthousandthofamonut.mul(holderFee)) + uint(tenthousandthofamonut.mul(liqproviderFee));

        // Balance updates should be done by considering whether the transaction sender or the receiver is an excluded address or not
        if ((_isExcluded(_to)) && (_isExcluded(_from))){
            userbalanceOf[_from] -= _value;
            userbalanceOf[_to] +=   (_value).sub(totalOut);
        } else if(_isExcluded(_to)){
            userbalanceOf[_from] -= _value.mul(transferRate);
            userbalanceOf[_to] +=   (_value).sub(totalOut);
        } else if (_isExcluded(_from)){
            userbalanceOf[_from] -= _value;
            uint transferAmount = (_value).sub(totalOut);
            userbalanceOf[_to] +=  transferAmount.mul(transferRate);
        } else{
            userbalanceOf[_from] -= _value.mul(transferRate);
            uint transferAmount = (_value).sub(totalOut);
            userbalanceOf[_to] +=   transferAmount.mul(transferRate);
        }

        // 0.75% of an on-chain transaction is instantly distributed to the token holders
        // Remaining 1.25% of the transaction fee is sent to the smart contract
        uint includedRewards = tenthousandthofamonut.mul(holderFee);
        userbalanceOf[address(this)] += (totalOut - includedRewards);
        // Amount of tokens to be sent to the token holders
        uint transactionStakerFee = includedRewards.mul(transferRate);

        if(PERASupply.sub(_removeExcludedAmounts().add(includedRewards)) < 1){
            userbalanceOf[address(this)] += includedRewards;
        }else{
            uint reduceTransferRate = transactionStakerFee.div(PERASupply.sub(_removeExcludedAmounts()));
            transferRate -= reduceTransferRate;
        }

        // Parameters to be sent to the daily trading competition functions:
        // Transacted amount (_value)
        // Address of the user
            // If the transaction sender is a non-excluded address then the _from address is sent
            // If the transaction sender is an excluded address then the _to address is sent
        // How many days have passed since the contract creation (_bnum)
        tradingComp(_value, _from, _bnum);
        if(_isExcluded(_from) && !isManager(_from) && !_isExcluded(_to)){
                tradingComp(_value, _to, _bnum);
        }
        emit Transfer(_from, _to, uint(_value).sub(totalOut));
    }

    // Checks whether a trading competition winner claimed its competition rewards or not
    mapping (string => bool) public isPaid;
    // Checks if a given address has made an on-chain transaction for a given day
    mapping (string => bool) public isTraderIn;

    // traderAddress: Addresses of Top-10 volume generators for a given day
    // traderVolume: Daily volume of the Top-10 volume generators for a given day
    struct topTraders {
      address traderAddress;
      uint256 traderVolume;
    }
    mapping(uint => topTraders[]) public tTraders;

    // lastTVolume: Daily volume of the user who has the least daily generated volume within the Top-10 traders list (tTraders list)
    // lastTIndex: Index of the trader who has the least volume within the Top-10 traders list (tTraders list)
    struct findTopLast {
      uint256 lastTVolume;
      uint256 lastTIndex;
    }
    mapping(uint256 => findTopLast) public findTLast;
    mapping(string => uint256) public tcdetailz;

    //PERA Sort Algorithm:
    function tradingComp(uint256 _value, address _addr, uint _bnum) internal {
        // Check if the transacted amount is more than 100 PERA tokens and the given address is not in the excluded holders list
        if((_value > minTCamount) && (!_isExcluded(_addr))){
        string memory TCX = nMixAddrandSpBlock(_addr, _bnum);
            // Check if the user address has previously made an on-chain transaction
            if(!isTraderIn[TCX]){
               isTraderIn[TCX] = true;
               // Update user's daily trading volume
               tcdetailz[TCX] = _value;
                // Check if the length of the tTraders list has reached 10
                if(tTraders[_bnum].length < totalTCwinners){
                    // Push user's address and daily volume to the tTraders list
                    tTraders[_bnum].push(topTraders(_addr, _value));
                    // If the tTraders list is full (There should be 10 unique users within the list)
                    // Find the minimum daily volume value within the Top-10 traders list
                    if(tTraders[_bnum].length == totalTCwinners){
                            uint minVolume = tTraders[_bnum][0].traderVolume;
                            uint minIndex = 0;
                        for(uint i=0; i<tTraders[_bnum].length; i++){
                            if(tTraders[_bnum][i].traderVolume < minVolume){
                                minVolume = tTraders[_bnum][i].traderVolume;
                                minIndex = i;
                            }
                        }
                    // lastTVolume: Minimum daily volume within the Top-10 traders list
                    // lastTIndex: Index of the user who has the least volume within the Top-10 traders list
                    findTLast[_bnum].lastTVolume = minVolume;
                    findTLast[_bnum].lastTIndex = minIndex;
                    }
                }
                // When the Top-10 traders list (tTraders) is filled, check if the current user's daily volume is larger than
                // the user who has the least volume within the Top-10 traders
                else{
                    if(tcdetailz[TCX] > findTLast[_bnum].lastTVolume){
                        topTradersList(tcdetailz[TCX], _bnum, _addr);
                    }
                }
            }
            // If the user address has previously made an on-chain transaction
            else{
                // Update user's daily trading volume
                tcdetailz[TCX] += _value;
                // Check if length of the tTraders list has reached 10
                // If not, then find the user's index within the tTraders list and update the volume on the corresponding index point
                if(tTraders[_bnum].length != totalTCwinners){
                    uint256 updateIndex = findTraderIndex(_bnum, _addr);
                    tTraders[_bnum][updateIndex].traderVolume = tcdetailz[TCX];
                // If length of the tTraders list has reached 10
                }else{
                    // Check if the user's volume is larger than the minimum daily volume within the Top-10 traders list
                    if(tcdetailz[TCX] > findTLast[_bnum].lastTVolume){
                        // Check if the current user is already in the Top-10 if not, update tTraders list (see function topTradersList)
                        if(!isTopTrader(_bnum, _addr)){
                            topTradersList(tcdetailz[TCX], _bnum, _addr);
                        // Check if the current user has the least volume in the Top-10 traders list if so, update tTraders list (see function updateLastTrader)
                        }else if(tTraders[_bnum][findTLast[_bnum].lastTIndex].traderAddress == _addr){
                            updateLastTrader(tcdetailz[TCX], _bnum, _addr);
                        // Check if the current user is already in the Top-10 traders list but not the 10th rank if so,
                        // only update the user's daily volume in the tTraders list
                        }else if(isTopTrader(_bnum, _addr) && tTraders[_bnum][findTLast[_bnum].lastTIndex].traderAddress != _addr){
                            uint256 updateIndex = findTraderIndex(_bnum, _addr);
                            tTraders[_bnum][updateIndex].traderVolume = tcdetailz[TCX];
                        }
                    }
                }
            }
        }
    }

    // Function is used if the user who has the least daily volume wtihin the Top-10 traders list makes a transaction
    function updateLastTrader(uint256 _value, uint256 _bnum, address _addr) internal {

        // Check if the updated daily volume of the user can overtake rank 9
        // If not, 10th rank remains in the same spot and its daily volume gets updated
        if(_value < checkUserVolume(sortTraders(_bnum)[8], _bnum)){
            tTraders[_bnum][findTraderIndex(_bnum, _addr)].traderVolume = _value;
            findTLast[_bnum].lastTVolume = _value;
        }
        // If the updated daily volume of the user can overtake rank 9
        // then find the new minimum volume in the Top-10 traders list and the corresponding index point
        else{
            tTraders[_bnum][findTLast[_bnum].lastTIndex].traderVolume = _value;
            uint256 minVolume = tTraders[_bnum][0].traderVolume;
            uint256 minIndex;
            for(uint i=0; i<tTraders[_bnum].length; i++){
                if(tTraders[_bnum][i].traderVolume <= minVolume){
                    minVolume = tTraders[_bnum][i].traderVolume;
                    minIndex = i;
                }
            }
            findTLast[_bnum].lastTVolume = minVolume;
            findTLast[_bnum].lastTIndex = minIndex;
        }
    }

    // Function is used when a user who is not in the Top-10 traders list makes it to the Top-10 traders list
    // New user's address and daily volume are stored on the previous 10th rank's index in the tTraders list
    // Minimum daily volume within the new Top-10 traders list and the corresponding index point is calculated
    function topTradersList(uint256 _value, uint256 _bnum, address _addr) internal {

        uint256 minVolume = _value;
        uint256 minIndex;

        tTraders[_bnum][findTLast[_bnum].lastTIndex].traderAddress = _addr;
        tTraders[_bnum][findTLast[_bnum].lastTIndex].traderVolume = _value;
        for(uint i=0; i<tTraders[_bnum].length; i++){
            if(tTraders[_bnum][i].traderVolume <= minVolume){
                minVolume = tTraders[_bnum][i].traderVolume;
                minIndex = i;
            }
        }
        findTLast[_bnum].lastTVolume = minVolume;
        findTLast[_bnum].lastTIndex = minIndex;
    }

    // Function checks if a given address is in the Top-10 traders list for a given day
    function isTopTrader(uint _bnum, address _addr) view public returns(bool) {
        bool checkTopTrader;
        for(uint i=0; i < tTraders[_bnum].length; i++){
        if(tTraders[_bnum][i].traderAddress == _addr){
            checkTopTrader = true;
        }
      }
      return  checkTopTrader;
   }

    // Function checks the index point of a user within the tTraders list
    function findTraderIndex(uint _bnum, address _addr) view public returns(uint256) {
        uint256 checkIndex;
        for(uint i=0; i < tTraders[_bnum].length; i++){
        if(tTraders[_bnum][i].traderAddress == _addr){
            checkIndex = i;
        }
      }
      return  checkIndex;
   }

    // View function for users to see if they are in the Top-10 traders list
    function checkTopTraderList(uint _bnum, uint _Ranking) view public returns(address) {
      return  tTraders[_bnum][_Ranking].traderAddress;
    }


    // Contract stores the Top-10 trader's daily volume and addresses within the tTraders list however
    // the list is not sorted until someone claims the trading competition rewards
    function sortTraders(uint _bnum) view public returns(address[] memory) {
      uint8 wlistlimit = totalTCwinners;
      address[] memory dailyTCWinners = new address[](wlistlimit);
      uint maxTradedNumber = 0;
      address maxTraderAdd;

      for(uint k=0; k<wlistlimit; k++){
          for(uint j=0; j < tTraders[_bnum].length; j++){
                if(!isUserWinner(dailyTCWinners, tTraders[_bnum][j].traderAddress)){
                    if(tTraders[_bnum][j].traderVolume > maxTradedNumber) {
                        maxTradedNumber = tTraders[_bnum][j].traderVolume;
                        maxTraderAdd = tTraders[_bnum][j].traderAddress;
                        dailyTCWinners[k] = maxTraderAdd;
                    }
                } else {
                   maxTraderAdd = address(0);
                }
          }
          maxTradedNumber = 0;
       }
      return  dailyTCWinners;
      }

    // Function checks if a user's address in the Top-10 traders list is already placed in the proper spot while sorting
    function isUserWinner(address[] memory dailyTCList,address _addr) view private returns (bool) {
        for(uint l=0; l < dailyTCList.length; l++){
            if(_addr == dailyTCList[l]){
                return  true;
            }
        }
    return false;
    }

    // View function for users to check their daily volume for a given day
    function checkUserVolume(address _addr, uint256 bnum)  public view returns(uint) {
         string memory TCX = nMixAddrandSpBlock(_addr, bnum);
         return tcdetailz[TCX];
    }

    // Function checks the placement of a user who wins the trading competition (Returns the rank of the user in the Top-10 traders list)
    function checkUserTCPosition(address[] memory userinTCList,address _addr) view private returns (uint) {
        for(uint l=0; l < userinTCList.length; l++){
            if(_addr == userinTCList[l]){
                return  l;
            }
        }
        return totalTCwinners;
    }

    // Function to calculate the trading competition rewards for each winner
    function calculateUserTCreward(address _addr, uint _bnum)  public view returns(uint256, uint256, uint256, uint256, uint256) {
     if(_addr == address(0x0)) { return (404,404,404,404,404); } else {
     address[] memory getLastWinners = new address[](totalTCwinners);
     // Calculate how many days have passed since the user won the trading competition
     // Claimable trading competition reward for a user is calculated as = User's total reward*(51+(7*Days passed since the user won the trading competition))/100
     // It takes at least 7 days for a winner to be able to claim %100 of all its trading competition rewards
     uint rDayDifference = (block.number.sub(genesisBlock.add(_bnum.mul(BlockSizeForTC)))).div(BlockSizeForTC);
     _bnum = _bnum.sub(1);
     if(rDayDifference > 7){rDayDifference=7;}

     getLastWinners = sortTraders(_bnum);
     if(isUserWinner(getLastWinners, _addr)){
         // Find user's placement in the Top-10 traders list (User's placement when the tTraders list is sorted wrt each user's daily volume)
         uint winnerIndex = checkUserTCPosition(getLastWinners, _addr);
         // Check if a user has already claimed its trading competition rewards
         if(!isPaid[nMixAddrandSpBlock(msg.sender, _bnum)]){
            // Trading competition reward share of a user is calculated as = 19-(2*User's rank in the list)
            // User's index in the Top-10 traders list = User's rank in the Top-10 traders list - 1
            uint256 rewardRate = uint(19).sub(uint(2).mul(winnerIndex));
            // If 10 years have passed since the contract creation, then the emission reward = 0
            uint256 rewardEmission = 0;
            if((_bnum*BlockSizeForTC) < tenYearsasBlock){
                rewardEmission = dailyRewardForTC.mul(TCRewardMultiplier).mul(rewardRate).div(1000); // Total emission reward for the user
            }
            uint256 rewardFee = totalRewardforTC[_bnum];
            rewardFee = rewardFee.mul(rewardRate).div(100);     // Total transaction fee reward for the user
            uint256 traderReward = rewardEmission + rewardFee;  // Total reward for the user

            rewardFee = rewardFee.mul(51+(7*rDayDifference)).div(100);              // Eligible transaction fee rewards
            rewardEmission = rewardEmission.mul(51+(7*rDayDifference)).div(100);    // Eligible emission rewards
            uint256 traderRewardEligible = traderReward.mul(51+(7*rDayDifference)).div(100); // Total eligible rewards
            return (traderReward, traderRewardEligible, winnerIndex, rewardEmission, rewardFee);
         } else {return (404,404,404,404,404);}
     } else {return (404,404,404,404,404);} }
    }

    // Function to calculate the trading competition rewards for each winner
    function pendingTCreward(address _addr, uint _bnum)  external view returns(uint256, uint256, uint256, uint256, uint256) {
     if(_addr == address(0x0)) { return (404,404,404,404,404); } else {
     address[] memory getLastWinners = new address[](totalTCwinners);
     uint rDayDifference = (block.number.sub(genesisBlock.add(_bnum.mul(BlockSizeForTC)))).div(BlockSizeForTC);
     if(rDayDifference > 7){rDayDifference=7;}
     getLastWinners = sortTraders(_bnum);
     if(isUserWinner(getLastWinners, _addr)){
         uint winnerIndex = checkUserTCPosition(getLastWinners, _addr);
         if(!isPaid[nMixAddrandSpBlock(msg.sender, _bnum)]){
            uint256 rewardRate = uint(19).sub(uint(2).mul(winnerIndex));
            uint256 rewardEmission = 0;
            if((_bnum*BlockSizeForTC) < tenYearsasBlock){
                rewardEmission = dailyRewardForTC.mul(TCRewardMultiplier).mul(rewardRate).div(1000);
            }
            uint256 rewardFee = totalRewardforTC[_bnum];
            rewardFee = rewardFee.mul(rewardRate).div(100);
            uint256 traderReward = rewardEmission + rewardFee;
            rewardFee = rewardFee.mul(51+(7*rDayDifference)).div(100);
            rewardEmission = rewardEmission.mul(51+(7*rDayDifference)).div(100);
            uint256 traderRewardEligible = traderReward.mul(51+(7*rDayDifference)).div(100);
            return (traderReward, traderRewardEligible, winnerIndex, rewardEmission, rewardFee);
         } else {return (404,404,404,404,404);}
     } else {return (404,404,404,404,404);} }
    }

    // Funciton for trading competition winners to claim their rewards
    function getTCreward(uint _bnum) external {
         require(_bnum > 0,"min 1 ended TC is required.");
         require(_bnum.sub(1) < showBnum(), 'At least 1 day is Required!');
         (uint256 _traderReward, uint256 _traderRewardEligible, uint _winnerIndex, uint256 _rewardEmission, uint256 _rewardFee) = calculateUserTCreward(msg.sender, _bnum);
         require(_traderRewardEligible > 0, 'No Eligible Reward!');
         require(!isPaid[nMixAddrandSpBlock(msg.sender, _bnum.sub(1))]);
         if(_winnerIndex != 404) {
         isPaid[nMixAddrandSpBlock(msg.sender, _bnum.sub(1))] = true;
         _mint(msg.sender, _rewardEmission);
         _transfer(address(this), msg.sender, _traderRewardEligible);
         }
    }

    // Function calculates how many days have passed since the contract creation
    function showBnum() public view returns(uint256) {
        return (block.number - genesisBlock)/BlockSizeForTC;
    }

    // Function is used for mixing the data of a user's address and how many days have passed since the contract creation
    // It is used for combining a unique data (address) with a non-unique but necessary data (# of the day) to create a single unique data to be used for indexing
    function nMixAddrandSpBlock(address _addr, uint256 bnum)  public view returns(string memory) {
         return append(uintToString(nAddrHash(_addr)),uintToString(bnum));
    }

    function uintToString(uint256 v) internal pure returns(string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    function nAddrHash(address _address) view private returns (uint256) {
        return uint256(_address) % 10000000000;
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a,"-",b));
    }

    // Returns block rewards over a given _from to _to block number multiplied with the reward multiplier for LP token stakers
    function getDistReward(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(LPRewardMultiplier);
    }

    struct LPUserInfo {
        uint256 userLPamount;
        uint256 userReflectedLP;
    }

    mapping (address => LPUserInfo) public userInfo;

    // View function for LP token stakers to see pending PERA rewards
    function pendingPERA(address _user) external view returns (uint256) {

        LPUserInfo storage user = userInfo[_user];
        uint256 vLPRate = LPRate;
        uint256 vtotalStakedLP = totalStakedLP;
        if (block.number > lastRewardBlock && vtotalStakedLP != 0) {
            uint256 distance = getDistReward(lastRewardBlock, block.number);
            uint256 PERAEmissionReward = distance.mul(blockRewardLP).div(200);
            uint PERAReward = PERAEmissionReward + FeeRewPoolLP;
            vLPRate = vLPRate.add(PERAReward.mul(1e12).div(vtotalStakedLP));
        }
        return user.userLPamount.mul(vLPRate).div(1e12).sub(user.userReflectedLP);
    }

    // Function for staking LP tokens (min 1 LP token is required)
    function depositLPtoken(uint256 _amount) external {

        LPUserInfo storage user = userInfo[msg.sender];
        updateRate(totalStakedLP);

        if (user.userLPamount > 0) {
            uint256 pendingReward = user.userLPamount.mul(LPRate).div(1e12).sub(user.userReflectedLP);
            if(pendingReward > 0) {
                _transfer(address(this), msg.sender, pendingReward);
            }
        }
        if (_amount > 1 * 10 ** LPTokenDecimals) {
            totalStakedLP += _amount;
            user.userLPamount = user.userLPamount.add(_amount);
            ERC20(lpTokenAddress).transferFrom(msg.sender, address(this), _amount);
        }
        user.userReflectedLP = user.userLPamount.mul(LPRate).div(1e12);
    }

    // Function updates variables related to LP token staker reward distribution
    function updateRate(uint256 _totalStakedLP) internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (_totalStakedLP == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 distance = getDistReward(lastRewardBlock, block.number);
        uint256 PERAEmissionReward = distance.mul(blockRewardLP).div(200);
        if((block.number - genesisBlock) > tenYearsasBlock){
            PERAEmissionReward = 0;
        }
        uint PERAReward = PERAEmissionReward + FeeRewPoolLP;
        FeeRewPoolLP = 0;
        _mint(msg.sender, PERAEmissionReward);
        LPRate = LPRate.add(PERAReward.mul(1e12).div(_totalStakedLP));
        lastRewardBlock = block.number;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: mint to the zero address');

        totalSupply = totalSupply.add(amount);
        PERASupply = PERASupply.add(amount);
        userbalanceOf[address(this)] += amount;
    }

    // Withdraw without receiving LP token staker rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _exit) external {
        LPUserInfo storage user = userInfo[msg.sender];
        totalStakedLP -= user.userLPamount;
        ERC20(lpTokenAddress).transfer(msg.sender,  user.userLPamount);
        user.userLPamount = 0;
        user.userReflectedLP = 0;
        if(totalStakedLP == 0){
            FeeRewPoolLP = 0;
        }
    }

    // Function is used to withdraw LP tokens from the PERA smart contract
    function withdraw(uint256 _amount) external {

        LPUserInfo storage user = userInfo[msg.sender];
        require(user.userLPamount >= _amount, "withdraw: not good");
        updateRate(totalStakedLP);

        uint256 pendingReward = user.userLPamount.mul(LPRate).div(1e12).sub(user.userReflectedLP);
        if(pendingReward > 0) {
            _transfer(address(this), msg.sender, pendingReward);
        }
        if(_amount > 0) {
            user.userLPamount = user.userLPamount.sub(_amount);
            totalStakedLP -= _amount;
            ERC20(lpTokenAddress).transfer(msg.sender,  _amount);
        }
        if(totalStakedLP == 0){
            FeeRewPoolLP = 0;
        }
        user.userReflectedLP = user.userLPamount.mul(LPRate).div(1e12);
    }
 }