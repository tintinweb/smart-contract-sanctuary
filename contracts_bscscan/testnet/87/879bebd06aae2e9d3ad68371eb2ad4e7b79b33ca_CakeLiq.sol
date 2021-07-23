// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// IMPORTS
import "./iBEP20.sol";   // BEP20 Interface
import "./pancake.sol";  // Pancakeswap Router Interfaces

contract CakeLiq {
    
    struct Job {
        bytes32 JOBID;
        address client;
        address provider;
        uint amount;
        bool released;
    }
                                       
    address public owner;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;     // Canonical WBNB address used by Pancake
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;     // Settlement BUSD contract address
    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;   // Pancake V2 ROUTER
    IPancakeRouter01 pancakeSwap = IPancakeRouter01(ROUTER);       // Define PancakeSwap Router  

    bytes32[] jobList;
    uint jobCounter;
    uint DEFAULT_FEE;                            

    mapping(bytes32 => bool) public jobExists;                               
    mapping(bytes32 => bool) public jobReleased;
    mapping(bytes32 => uint) public mapJobToAmount;
    mapping(bytes32 => address) public mapJobToClient;
    mapping(bytes32 => address) public mapJobToProvider;

    event Deposit(address indexed client, address indexed provider, uint value, bytes32 JOBID);
    event Release(address indexed client, address indexed provider, uint value, bytes32 JOBID);
    event SetOwner(address onwer, address newOwner);
 
    constructor() {
        owner = msg.sender;
        DEFAULT_FEE = uint(10**18 / 100);  // 1%
    }

    // Only Owner can execute
    modifier onlyAdmin() {
        require(msg.sender == owner, "!Auth");
        _;
    }

    // DEPOST BNB
    // Client to Deposit BNB with a JOBID
    function depositBNB(address provider, bytes32 JOBID) external payable {
        require(msg.value > 0, "no val");
        require(!jobExists[JOBID], "ID Err");

        jobExists[JOBID] = true;
        mapJobToClient[JOBID] = msg.sender;
        mapJobToProvider[JOBID] = provider;
        
        // Call internal swap function
        //uint _finalBUSD = _pancakeSwap(WBNB, msg.value);
        mapJobToAmount[JOBID] = msg.value;
        
        jobList.push(JOBID);
        jobCounter++;
           
        emit Deposit (msg.sender, provider, msg.value, JOBID);
    } 

    // DEPOSIT BEP20
    // Client to Deposit BEP20 asset with a JOBID
    function depositBEP20(address asset, address provider, uint value, bytes32 JOBID) external {
        require(value > 0, "no val");
        require(!jobExists[JOBID], "!ID");
        require(iBEP20(asset).transferFrom(msg.sender, address(this), value));

        jobExists[JOBID] = true;
        mapJobToClient[JOBID] = msg.sender;
        mapJobToProvider[JOBID] = provider;

        uint _finalBUSD; 
        if (asset == BUSD) {
            _finalBUSD = value;                             // Skips the swap if BEP20 token = BUSD
        } else {
            iBEP20(asset).approve(ROUTER, value);           // Approve Pancake Router to spend the deposited token
            _finalBUSD = _pancakeSwap(asset, value);        // Call internal swap function
        }   
        mapJobToAmount[JOBID] = _finalBUSD;
        
        jobList.push(JOBID);
        jobCounter++;

        emit Deposit(msg.sender, provider, _finalBUSD, JOBID);
    }

    // RELEASE BY CLIENT
    // Client Releases to transfer to Provider
    function releaseAsClient(bytes32 JOBID) external {
        require(jobExists[JOBID], "!ID");
        require(mapJobToClient[JOBID] == msg.sender, "!Auth");
        require(!jobReleased[JOBID], "ID Err");

        jobReleased[JOBID] = true;

        // Release Recipient = Provider
        address _recipient = mapJobToProvider[JOBID];
        uint _amount = mapJobToAmount[JOBID];
        uint _finalRelease = _releaseWithFee(_recipient, _amount);

        emit Release(msg.sender, _recipient, _finalRelease, JOBID);
    }

    // RELEASE BY PROVIDER
    function releaseByProvider (bytes32 JOBID) external {
        require(jobExists[JOBID], "!ID");
        require(mapJobToProvider[JOBID] == msg.sender, "!Auth");
        require(!jobReleased[JOBID], "ID Err");
        
        jobReleased[JOBID] = true;

        // Release Recipient = Client
        address _recipient = mapJobToClient[JOBID];
        uint _amount = mapJobToAmount[JOBID];
        uint _finalRelease = _releaseWithFee(_recipient, _amount);

        emit Release (msg.sender, _recipient, _finalRelease, JOBID);
    }

    // RELEASE BY ADMIN
    // Admin to call function specifying *payout amount* to Client and Provider
     function releaseByAdmin(bytes32 JOBID, uint clientSplit, uint providerSplit) external onlyAdmin {
        address _client = mapJobToClient[JOBID];
        address _provider = mapJobToProvider [JOBID];
        uint _amount = mapJobToAmount[JOBID];
        
        require(jobExists[JOBID], "!ID");
        require(!jobReleased[JOBID], "ID Err");
        require((clientSplit + providerSplit < _amount), "split err");      
        
        jobReleased[JOBID] = true;
  
        uint _clientFinalRelease = _releaseWithFee(_client, clientSplit);
        uint _providerFinalRelease = _releaseWithFee(_provider, providerSplit);

        emit Release(msg.sender, _client, _clientFinalRelease, JOBID);
        emit Release(msg.sender, _provider, _providerFinalRelease, JOBID);
    }
    
    // PANCAKESWAP CALL 
    function _pancakeSwap (address assetIn, uint amountIn) internal returns(uint _finalBUSD){
        uint amountOutMin = 1;
        address[] memory path = new address[](2);
        path[0] = assetIn;
        path[1] = BUSD;
        uint deadline = block.timestamp + 900; // 15 mins
        
        if (assetIn == WBNB) {
            // BNB liquidation to BUSD via PancakeSwap function call `swapExactETHForTokens`
             uint[] memory _amount = pancakeSwap.swapExactETHForTokens{value: amountIn}(
                amountOutMin, 
                path, 
                address(this), 
                deadline
            ); 
            _finalBUSD = _amount[1];              
        } else {
            // BEP20 liquidated to BUSD via PancakeSwap function call `swapExactTokensForTokens`
            uint[] memory _amounts = pancakeSwap.swapExactTokensForTokens(
                amountIn, 
                amountOutMin, 
                path, 
                address(this), 
                deadline
            );
            _finalBUSD = _amounts[1];
        }
    }

    // Internal function to handle Release
    // Calculates recipient & fee amounts and Transfers funds
    function _releaseWithFee(address _recipient, uint _amount) internal returns (uint) {
        
        uint _feeAmount = DEFAULT_FEE * _amount / (10**18) ;
        uint _amountMinusFee = _amount - _feeAmount; 
        
        require (_amount > 0, "Err 1");
        require (_amountMinusFee > 0 , "Err 2"); 
        require (_amount > _amountMinusFee, "Err 3");
        
        require (iBEP20(BUSD).transfer(_recipient, _amountMinusFee)); 
        return _amountMinusFee;
    }

    //======= ADMIN =======//

    // Changes Contract Owner
    function setOwner(address newOwner) external onlyAdmin {
        owner = newOwner;
        emit SetOwner(owner, newOwner);
    }

    // Change Default Fee
    function changeDefaultFee(uint newFee) external onlyAdmin {
        require (newFee != DEFAULT_FEE);
        require (newFee > 1 && newFee < uint(10**20));
        DEFAULT_FEE = newFee;
    }
    
    // Exports specified sssets from this escrow contract
    function exportFunds(address asset, address payable recipient) external onlyAdmin {
        if (asset == address(0)) {                       // BNB 
            uint _balance = address(this).balance;
            if (_balance > 0) {
                recipient.transfer(_balance);
            }
        } else {                                        // BEP20
            uint _balance = _getBalance(asset);         
            iBEP20(asset).transfer(recipient, _balance);
        }
    }
    
    //======= HELPERS  =======//
    
    // Gets balance of any BEP20 asset in the contract
    function _getBalance(address asset) internal view returns (uint _balance){
        _balance = iBEP20(asset).balanceOf(address(this));
    }
  
    // Returns Job Details
    function getJobs () external view returns (uint jobCount, Job [] memory allJobs){
        uint _jobCount = jobList.length;
        Job [] memory jobArray = new Job [](_jobCount);
        
        for (uint i = 0; i < _jobCount; i++) {
            bytes32 _ID = jobList[i];
            Job memory j;

            j.JOBID = _ID;
            j.amount = mapJobToAmount[_ID];
            j.client = mapJobToClient[_ID];
            j.provider = mapJobToProvider[_ID];
            j.released = jobReleased[_ID];   
            jobArray[i] = j;
        }
        jobCount = _jobCount;
        allJobs = jobArray;
    }
}