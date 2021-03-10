/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

// SPDX-License-Identifier: NO-LICENSE

pragma solidity <=0.7.4;

library SafeMath {
    
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "multiplication overflow");

		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

}

interface IERC20{
	
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract PreSale{
    
    address public organisation;
    address payable public ethWallet;
    address public governor;
    address public admin;

    address public oracle;
    address public edgexContract;
    address public ethPriceSource;
    uint256 public presalePrice;   // $1 = 100000000 - 8 precision

    uint256 public maxCap;
    uint256 public minCap;
    
    bool public locked;
    
    struct History{
        uint256[] timestamps;
        uint256[] amounts;
        uint256[] paymentMethod;
        uint256[] price;
    }
    
    mapping(address => uint256) public allocated;
    mapping(address => uint256) public purchased;
    mapping(address => History) private history;
    mapping(address => bool) public whitelisted;

    event Purchase(address indexed to, uint256 amount);
    
    /**
     * contract address of edgex token & price oracle to be passed as an argument to constructor
    */
    
    constructor(
        address _ethWallet, 
        address _organisation,
        address _governor,
        address _admin,
        address _ethSource,
        address _edgexContract,
        uint256 _presalePrice
        )
    {
        organisation = _organisation;
        ethWallet = payable(_ethWallet);
        governor = _governor;
        admin = _admin;
        edgexContract = _edgexContract;
        ethPriceSource = _ethSource;
        presalePrice = _presalePrice;
    }
    

    modifier onlyAdmin(){
        require(msg.sender == admin,"Caller not admin");
        _;
    }
    
    modifier onlyGovernor(){
        require(msg.sender == governor, "Caller not Governor");
        _;
    }

    modifier isWhitelisted(address _user){
        require(whitelisted[_user] == true,"Address not verified");
        _;
    }
    
    function purchase(address _reciever) public payable returns(bool){
        uint256 tokens = calculate(msg.value);
        require(tokens >= minCap,"ValueError");
        require(purchased[_reciever] < maxCap,"ValueError");
        require(whitelisted[_reciever] == true,"Address not verified");
        purchased[_reciever] = SafeMath.add(purchased[_reciever],tokens);
        if(locked){
            allocated[_reciever] = SafeMath.add(allocated[_reciever],tokens);
            ethWallet.transfer(msg.value);
        }
        else{
            IERC20(edgexContract).transfer( _reciever,tokens);
            IERC20(edgexContract).transfer(
                organisation,
                SafeMath.div(tokens,100)
            );
            ethWallet.transfer(msg.value);
        }
        History storage h = history[_reciever];
        h.timestamps.push(block.timestamp);
        h.amounts.push(tokens);
        h.price.push(presalePrice);
        emit Purchase(_reciever,tokens);
        return true;
    }
    
    /**
     * Used for calculate the amount of tokens purchased
     * returns an uint256 which is 18 decimals of precision
     * Equivalent amount of EDGX Tokens to be transferred.
    */
    
    function calculate(uint256 _amount) private view returns(uint256){
        uint256 value = uint256(fetchEthPrice());
                value = SafeMath.mul(_amount,value);
        uint256 tokens = SafeMath.div(value,presalePrice);
        return tokens;
    }
    
    /**
     * Used to allocated tokens for purchase through other methods
     * Send the amount to be allocated as 18 decimals
    */
    
    function allocate(uint256 _tokens,address _user, uint256 _method) public onlyAdmin returns(bool){
        require(_tokens >= minCap,"ValueError");
        require(purchased[_user] <= maxCap,"ValueError");
        if(locked){
          allocated[_user] = SafeMath.add(allocated[_user],_tokens);
          purchased[_user] = SafeMath.add(purchased[_user],_tokens);
        }
        else { 
            IERC20(edgexContract).transfer(_user,_tokens);
            IERC20(edgexContract).transfer(
                organisation,
                SafeMath.div(_tokens,100)
            );
        }
        History storage h = history[_user];
        h.timestamps.push(block.timestamp);
        h.amounts.push(_tokens);
        h.price.push(presalePrice);
        h.paymentMethod.push(_method);
        emit Purchase(_user,_tokens);
        return true;
    }
    
    /**
     * Reduce allocated tokens of an user from the user"s allocated value
    */
    
    function reduceAllocation(uint256 _tokens, address _user) public onlyAdmin returns(bool){
        allocated[_user] = SafeMath.sub(allocated[_user],_tokens);
        return true;
    }
    
    /**
     * Used to transfer pre-sale tokens for other payment options
    */
    
    function fetchPurchaseHistory(address _user) 
        public view 
        returns(
            uint256[] memory _timestamp, 
            uint256[] memory _amounts
        )
    {
        History storage h = history[_user];
        return(h.timestamps,h.amounts);
    }
    

     /**
        @dev changing the admin of the oracle
        Warning : Admin can add governor, remove governor
                  and can update price.
     */

    function revokeOwnership(address _newOwner) public onlyAdmin returns(bool){
        admin = payable(_newOwner);
        return true;
    }
    
    /**
     * @dev withdraw the tokens from the contract by the user 
    */
    
    function claim() public returns(bool){
        require(locked != true, "Sale Locked");
        require(allocated[msg.sender]>0, "No Tokens Allocated");
        uint256 transferAmount = allocated[msg.sender];
        allocated[msg.sender] = 0;
        IERC20(edgexContract).transfer(msg.sender,transferAmount);
        IERC20(edgexContract).transfer(
            organisation,
            SafeMath.div(transferAmount,100)
            );
        return true;
    } 

    /**
     * @dev fetches the price of Ethereum from chainlink oracle 
     */

    function fetchEthPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(ethPriceSource).latestRoundData();
        return price;
    }
    
    function whitelist(address _user) public onlyGovernor returns(bool){
        whitelisted[_user] = true;
        return true;
    }

    /**
      * @dev update the max and min cap
     */
    function updateCap(uint256 _minCap, uint256 _maxCap) public onlyGovernor returns(bool){
        maxCap = _maxCap;
        minCap = _minCap;
        return false;
    }

    function lockDistribution(bool _state) public onlyGovernor returns(bool){
        locked = _state;
        return true;
    }
    
    function updateGovernor(address _newGovernor) public onlyGovernor returns(bool){
        governor = _newGovernor;
        return true;
    }

    function updateOracle(address _oracle) public onlyAdmin returns(bool){
        oracle = _oracle;
        return true;
    }

    function updateContract(address _contract) public onlyAdmin returns(bool){
        edgexContract = _contract;
        return true;
    }

    function updateEthSource(address _ethSource) public onlyAdmin returns(bool){
        ethPriceSource = _ethSource;
        return true;
    }
    
    function updateEthWallet(address _newEthWallet) public onlyAdmin returns(bool){
        ethWallet = payable(_newEthWallet);
        return true;
    }
    
    function updateOrgWallet(address _newOrgWallet) public onlyAdmin returns(bool){
        organisation = _newOrgWallet;
        return true;
    }
    
    function drain(address _to, uint256 _amount) public onlyAdmin returns(bool){
        IERC20(edgexContract).transfer(_to,_amount);
        return true;
    }

}