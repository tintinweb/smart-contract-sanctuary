/**
 *Submitted for verification at cronoscan.com on 2022-05-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.7.0;

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
        require(c / a == b, "SafeMath: multiplication overflow");

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.7.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.7.0;

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


pragma solidity ^0.7.0;

contract ERC20Custom is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


pragma solidity ^0.7.0;

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


pragma solidity 0.7.6;

interface IBUCKPool {
    function toggleRecollateralize() external;
    function getRecollateralizePaused() external view returns (bool);
    function collatDollarBalance() external view returns (uint256);
    function getCollateralPrice() external view returns (uint256);
    function getMissingDecimals() external view returns(uint256);
    function sendExcessCollatToTreasury(uint256 _amount) external;
}


pragma solidity >=0.6.7;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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


pragma solidity 0.7.6;
interface ITreasury {
    function getCollateralSupply() external view returns (uint);
    function withdraw(uint) external;
}


pragma solidity 0.7.6;
interface V2Oracle {
    function assetToAsset(address, uint, address, uint32) external view returns (uint, uint);
}

pragma solidity >=0.6.7;

//BAND
interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

contract BUCK is ERC20Custom {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { BUCK, HERD }
    AggregatorV3Interface private cro_usd_chainlink;
    IStdReference private cro_usd_band;
    uint8 private cro_usd_chainlink_decimals;
    V2Oracle public oracle;
    ITreasury public treasury;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    uint256 public oracleMode;
    uint256 public cro_usd_oracle;
    address public owner_address;
    address public timelock_address; // Governance timelock address
    address public controller_address; // Controller contract to dynamically adjust system parameters automatically
    address public herd_address;
    address public wcro_address;
    address public cro_usd_chainlink_address;
    address public cro_usd_band_address;
    uint256 public immutable genesis_supply; // This is to help with establishing the Uniswap pools, as they need liquidity

    // The addresses in this array are added by the oracle and these contracts are able to mint buck
    address[] public buck_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public buck_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public buck_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of BUCK at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at USD 1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio
    uint256 public twap_period; // The twap period in seconds

    bool public collateral_ratio_paused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(buck_pools[msg.sender] == true, "Only buck pools can call this function");
        _;
    } 
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address || msg.sender == controller_address, "You are not the owner, controller, or the governance timelock");
        _;
    }

    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == owner_address 
            || msg.sender == timelock_address 
            || buck_pools[msg.sender] == true, 
            "You are not the owner, the governance timelock, or a pool");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _genesis_supply,
        address _wcro,
        address _oracle,
        address _treasury,
        address _cro_usd_band,
        address _timelock_address
    ) {
        name = _name;
        symbol = _symbol;
        genesis_supply = _genesis_supply;
        wcro_address = _wcro;
        oracle = V2Oracle(_oracle);
        oracleMode = 0; // Default to Twap
        cro_usd_oracle = 1; // Default to Band
        treasury = ITreasury(_treasury);
        timelock_address = _timelock_address;
        owner_address = msg.sender;
        _mint(owner_address, _genesis_supply);
        buck_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // BUCK system starts off fully collateralized (6 decimals of precision) > 100%
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // Collateral ratio will adjust according to the USD 1 price target at genesis
        price_band = 5000; // Collateral ratio will not adjust if between USD 0.995 and USD 1.005 at genesis
        twap_period = 3600; // default 3600 seconds (1 hour) twap period
        // CRO/USD Price Feed
        cro_usd_band_address = _cro_usd_band;
        cro_usd_band = IStdReference(cro_usd_band_address);
    }

    /* ========== VIEWS ========== */

    function getLatestPriceChainlink() internal view returns (int) {
        (,int price,,,) = cro_usd_chainlink.latestRoundData();
        return price;
    }

    function getLatestPriceBand() internal view returns (uint256) {
        IStdReference.ReferenceData memory data = cro_usd_band.getReferenceData("CRO","USD");
        return data.rate;
    }

    function getDecimals() internal view returns (uint8) {
        return cro_usd_chainlink.decimals();
    }
    
    function effectiveCollateralRatio() public view returns (uint){
        return globalCollateralValue().mul(1e6).div(totalSupply());
    }

    // Choice = 'BUCK' or 'HERD' for now
    function oracle_price(PriceChoice choice) internal view returns (uint256) {
        require(address(oracle) != address(0), "Oracle address have not set yet");
        require(herd_address != address(0), "HERD address have not set yet");

        uint256 price_vs_cro;

        if (choice == PriceChoice.BUCK) {
            // How much BUCK if you put in PRICE_PRECISION WCRO
            (uint p0, uint p1) = oracle.assetToAsset(wcro_address, PRICE_PRECISION, address(this), uint32(twap_period));
            
            if(oracleMode == 0){
                price_vs_cro = p0;
            } else if(oracleMode == 1){
                price_vs_cro = p1;
            }
            
        } else if (choice == PriceChoice.HERD) {
            // How much HERD if you put in PRICE_PRECISION WCRO
            (uint p0, uint p1) = oracle.assetToAsset(wcro_address, PRICE_PRECISION, herd_address, uint32(twap_period));
            
            if(oracleMode == 0){
                price_vs_cro = p0;
            } else if(oracleMode == 1){
                price_vs_cro = p1;
            }
            
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (BUCK) or 1 (HERD)");

        // Will be in 1e6 format
        return cro_usd_price().mul(PRICE_PRECISION).div(price_vs_cro);
    }

    function buck_price() public view returns (uint256) {
        return oracle_price(PriceChoice.BUCK);
    }

    function herd_price()  public view returns (uint256) {
        return oracle_price(PriceChoice.HERD);
    }

    function cro_usd_price() public view returns (uint256) {

        uint256 croUsdPrice = 0;

        //chainlink
        if(cro_usd_oracle == 0)
        {
            croUsdPrice = uint256(getLatestPriceChainlink()).mul(PRICE_PRECISION).div(uint256(10) ** cro_usd_chainlink_decimals);
        }
        //band 
        else if(cro_usd_oracle == 1)
        {
            croUsdPrice = uint256(getLatestPriceBand()).mul(PRICE_PRECISION).div(1e18);
        }

        return croUsdPrice;
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function buck_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
       
        uint256 cro_usd_latest_price = 0;

        if(cro_usd_oracle == 0)
        {
            cro_usd_latest_price = uint256(getLatestPriceChainlink()).mul(PRICE_PRECISION).div(uint256(10) ** cro_usd_chainlink_decimals);
        }
        //band 
        else if(cro_usd_oracle == 1)
        {
            cro_usd_latest_price = uint256(getLatestPriceBand()).mul(PRICE_PRECISION).div(1e18);
        }

        return (
            oracle_price(PriceChoice.BUCK), // buck_price()
            oracle_price(PriceChoice.HERD), // herd_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            cro_usd_latest_price
        );
    }

    // Iterate through all buck pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value_d18 = 0; 

        for (uint i = 0; i < buck_pools_array.length; i++){ 
            // Exclude null addresses
            if (buck_pools_array[i] != address(0)){
                total_collateral_value_d18 = total_collateral_value_d18.add(IBUCKPool(buck_pools_array[i]).collatDollarBalance());
            }

        }
        return total_collateral_value_d18;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        require(address(treasury) != address(0), "Treasury have not set yet");
        uint256 buck_price_cur = buck_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setBUCKStep()) 
        
        if (buck_price_cur > price_target.add(price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= buck_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio.sub(buck_step);
            }
        } else if (buck_price_cur < price_target.sub(price_band)) { //increase collateral ratio
            if(global_collateral_ratio.add(buck_step) >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio.add(buck_step);
            }
        }

        last_call_time = block.timestamp; // Set the time of the last expansion
        
        // Target CR VS Effective CR
        if(global_collateral_ratio < effectiveCollateralRatio()){
            // if collateral is excess and send it to treasury
            if(availableExcessCollatDV() > 0){
                IBUCKPool(buck_pools_array[0]).sendExcessCollatToTreasury(availableExcessCollatDV());
            }
            // Disable Recollaterize
            if(IBUCKPool(buck_pools_array[0]).getRecollateralizePaused() == false) {
                IBUCKPool(buck_pools_array[0]).toggleRecollateralize();
            }
        } else{
            // if collateral is insufficient then withdraw it from treasury to Pool
            uint256 recollat_possible = (global_collateral_ratio.mul(totalSupply()).sub(totalSupply().mul((effectiveCollateralRatio().add(1))))).div(1e6);
            uint256 treasuryCollateralBalance = treasury.getCollateralSupply();
            if(treasuryCollateralBalance > 0){
                if(treasuryCollateralBalance >= recollat_possible){
                    uint256 amount_to_recollat = recollat_possible.mul(1e6).div(IBUCKPool(buck_pools_array[0]).getCollateralPrice());
                    treasury.withdraw(amount_to_recollat.div(10 ** IBUCKPool(buck_pools_array[0]).getMissingDecimals()));
                } else{
                    // Enable Recollaterize
                    if(IBUCKPool(buck_pools_array[0]).getRecollateralizePaused() == true) {
                        IBUCKPool(buck_pools_array[0]).toggleRecollateralize();
                    }
                }
            }
        }
    }

    // Returns the value of excess collateral held in this Buck pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 globalCollateralRatio = global_collateral_ratio;

        if (globalCollateralRatio > COLLATERAL_RATIO_PRECISION) globalCollateralRatio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (totalSupply().mul(globalCollateralRatio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 BUCK with USD 1 of collateral at current collat ratio
        if (globalCollateralValue() > required_collat_dollar_value_d18) return globalCollateralValue().sub(required_collat_dollar_value_d18);
        else return 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burnFrom(b_address, b_amount);
        emit BUCKBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other buck pools will call to mint new BUCK 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit BUCKMinted(msg.sender, m_address, m_amount);
    }

    // Adds pool addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwnerOrGovernance {
        require(buck_pools[pool_address] == false, "address already exists");
        buck_pools[pool_address] = true; 
        buck_pools_array.push(pool_address);
        
        emit PoolAdded(buck_pools_array.length-1, pool_address);
    }

    // Change pool address on specific index
    function changePool(uint index, address new_pool_address) public onlyByOwnerOrGovernance {
        require(index < buck_pools_array.length, "index not found");
        
        address oldPool = buck_pools_array[index];
        
        require(buck_pools[oldPool] == true, "old address doesn't exist");

        // Delete from the mapping
        delete buck_pools[oldPool];

        // Update to new pool
        buck_pools[new_pool_address] = true; 
        buck_pools_array[index] = new_pool_address;
        
        emit PoolChanged(index, oldPool, new_pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerOrGovernance {
        require(buck_pools[pool_address] == true, "address doesn't exist already");
        
        // Delete from the mapping
        delete buck_pools[pool_address];

        uint deletedIndex;
        
        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < buck_pools_array.length; i++){ 
            if (buck_pools_array[i] == pool_address) {
                buck_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                deletedIndex = i;
                break;
            }
        }
        
        emit PoolRemoved(deletedIndex, pool_address);
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setTreasury(address _treasury) public onlyByOwnerOrGovernance {
        treasury = ITreasury(_treasury);
    }

    function setAssetCroOracle(address _oracle) public onlyByOwnerOrGovernance{
        oracle = V2Oracle(_oracle);
    }

    function setBUCKStep(uint256 _new_step) public onlyByOwnerOrGovernance {
        buck_step = _new_step;
    }  

    function setPriceTarget(uint256 _new_price_target) public onlyByOwnerOrGovernance {
        price_target = _new_price_target;
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerOrGovernance {
    	refresh_cooldown = _new_cooldown;
    }

    function setTwapPeriod(uint256 _new_twap_period) public onlyByOwnerOrGovernance {
    	twap_period = _new_twap_period;
    }

    function setHERDAddress(address _herd_address) public onlyByOwnerOrGovernance {
        herd_address = _herd_address;
    }

    function setCroUsdChainlinkAddress(address _cro_usd_chainlink_address) public onlyByOwnerOrGovernance {
        cro_usd_chainlink_address = _cro_usd_chainlink_address;
        cro_usd_chainlink = AggregatorV3Interface(cro_usd_chainlink_address);
        cro_usd_chainlink_decimals = getDecimals();
    }

    function setCroUsdBandAddress(address _cro_usd_band_address) public onlyByOwnerOrGovernance {
        cro_usd_band_address = _cro_usd_band_address;
        cro_usd_band = IStdReference(cro_usd_band_address);
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setController(address _controller_address) external onlyByOwnerOrGovernance {
        controller_address = _controller_address;
    }

    function setPriceBand(uint256 _price_band) external onlyByOwnerOrGovernance {
        price_band = _price_band;
    }

    function setWCRO(address _wcro_address) public onlyByOwnerOrGovernance {
        wcro_address = _wcro_address;
    }

    function toggleCollateralRatio() public onlyByOwnerOrGovernance {
        collateral_ratio_paused = !collateral_ratio_paused;
    }
    
    function setOracleMode(uint256 _mode) public onlyByOwnerOrGovernance{
        require(_mode < 2, "Choose between 0 or 1");
        // Mode Number Rules
        // 0 = Twap
        // 1 = Spot
        oracleMode = _mode;
    }

    function setCroUsdOracleProtocol(uint256 _oracle) public onlyByOwnerOrGovernance{
        require(_oracle < 2, "Choose between 0 or 1");
        // 0 = Chainlink
        // 1 = Band
        cro_usd_oracle = _oracle;
    }

    /* ========== EVENTS ========== */

    // Track BUCK burned
    event BUCKBurned(address indexed from, address indexed to, uint256 amount);

    // Track BUCK minted
    event BUCKMinted(address indexed from, address indexed to, uint256 amount);
    
    // Track Pool added
    event PoolAdded(uint index, address indexed pool);
    
    // Track Pool changed
    event PoolChanged(uint index, address indexed old_pool, address indexed new_pool);
    
    // Track Pool removed
    event PoolRemoved(uint index, address indexed pool);
}


pragma solidity 0.7.6;

contract HERD is ERC20Custom {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    
    uint256 public immutable genesis_supply;

    address public owner_address;
    address public timelock_address; // Governance timelock address
    BUCK public BUCKContract;

    bool public trackingVotes = true; // Tracking votes (only change if need to disable votes)

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(BUCKContract.buck_pools(msg.sender) == true, "Only buck pools can mint new HERD");
        _;
    }
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _genesis_supply,
        address buck_contract_address,
        address _timelock_address
    ) {
        name = _name;
        symbol = _symbol;
        genesis_supply = _genesis_supply;
        BUCKContract = BUCK(buck_contract_address);
        owner_address = msg.sender;
        timelock_address = _timelock_address;
        _mint(owner_address, _genesis_supply);

        // Do a checkpoint for the owner
        _writeCheckpoint(owner_address, 0, 0, uint96(_genesis_supply));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }
    
    function setBUCKAddress(address buck_contract_address) external onlyByOwnerOrGovernance {
        BUCKContract = BUCK(buck_contract_address);
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
    }
    
    // This function is what other buck pools will call to mint new HERD (similar to the BUCKContract mint) 
    function pool_mint(address m_address, uint256 m_amount) external onlyPools {        
        if(trackingVotes){
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = add96(srcRepOld, uint96(m_amount), "pool_mint new votes overflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // mint new votes
            trackVotes(address(this), m_address, uint96(m_amount));
        }
        
        super._mint(m_address, m_amount);
        emit HERDMinted(address(this), m_address, m_amount);
    }

    // This function is what other buck pools will call to burn HERD 
    function pool_burn_from(address b_address, uint256 b_amount) external onlyPools {
        if(trackingVotes){
            trackVotes(b_address, address(this), uint96(b_amount));
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = sub96(srcRepOld, uint96(b_amount), "pool_burn_from new votes underflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // burn votes
        }
        
        super._burnFrom(b_address, b_amount);
        emit HERDBurned(b_address, address(this), b_amount);
    }

    function toggleVotes() external onlyByOwnerOrGovernance {
        trackingVotes = !trackingVotes;
    }

    /* ========== OVERRIDDEN PUBLIC FUNCTIONS ========== */

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(_msgSender(), recipient, uint96(amount));
        }
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(sender, recipient, uint96(amount));
        }
        
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "HERD::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // From compound's _moveDelegates
    // Keep track of votes. "Delegates" is a misnomer here
    function trackVotes(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "HERD::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "HERD::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address voter, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "HERD::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[voter][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[voter][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[voter][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[voter] = nCheckpoints + 1;
      }

      emit VoterVotesChanged(voter, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /* ========== EVENTS ========== */
    
    /// @notice An event thats emitted when a voters account's vote balance changes
    event VoterVotesChanged(address indexed voter, uint previousBalance, uint newBalance);

    // Track HERD burned
    event HERDBurned(address indexed from, address indexed to, uint256 amount);

    // Track HERD minted
    event HERDMinted(address indexed from, address indexed to, uint256 amount);

}