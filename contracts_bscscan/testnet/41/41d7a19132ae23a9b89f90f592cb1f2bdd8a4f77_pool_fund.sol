/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.7.0 <0.9.0;

contract pool_fund {
    using SafeMath  for uint;

    modifier onlyOwner() {
        require(owner_address == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Received(address sender, uint amount);

    //uint public constant MINIMUM_LIQUIDITY = 10**3;
    //bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    //address public factory;
    //address public token0;
    //address public token1;

    //uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    //uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    //uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    //uint public price0CumulativeLast;
    //uint public price1CumulativeLast;
    //uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    bool private unlocked = true;
    bool out_bool;
    bool public claim_flag = false;

    uint256 number1;
    //uint256 total_deposited;
    uint256 maximum_fund;
    string public fund_token0;
    address public fund_token0_address;
    address public owner_address;
    address public gamer_address;
    address addr_out;

    uint256 public constant MAX_FEE = 10e16; // 10%
    uint256 public constant platform_fee = 5e16;
    uint256 private constant FEE_PRECISION = 1e18;
    uint256 public treasury_amount;
    uint256 public total_amount_to_claim;

    address[] investor_list;
    mapping(address => uint256) deposit_balances; // private??
    mapping(address => uint256) return_balances; // private??

    constructor(address _fund_token0_address, uint256 _maximum_fund) public {
        owner_address = msg.sender;
        IERC20(address(_fund_token0_address)).approve(address(this), 10e50);
        maximum_fund = _maximum_fund;
        fund_token0_address = _fund_token0_address;
    }

    function set_gamer_wallet(address _addr) public onlyOwner {
        gamer_address = _addr;
    }

    function is_address_exist(address _addr) internal returns(bool isexist){
        isexist = false;
        for (uint i; i < investor_list.length; i++) {
            if (investor_list[i] == address(_addr)) {
                isexist = true;
            }
        }
    }

    function get_investor_address(uint256 id_num) view public returns (address addr_out){
        addr_out = investor_list[id_num];
    }

    //function setBuybackFee(uint256 _newBuybackFee) external {
    //    require(hasRole(MAINTAINER, msg.sender));
    //    require(_newBuybackFee <= MAX_FEE, "The new fee is to high");
    //    buybackFee = _newBuybackFee;
    //    emit SetBuybackFee(buybackFee);
    //}

    function unlock_authorization(bool _true_false) public onlyOwner returns(bool unlocked) {
        unlocked = _true_false;
    }

    function change_owner(address _addr) public onlyOwner {
        require(unlocked == true, "unlock_authorization: Locked");
        owner_address = _addr;
    }

    function set_claim_flag(bool _true_false) public onlyOwner {
        claim_flag = _true_false;
    }

    function removeAddressArrayNoOrder(uint _index) internal {
        investor_list[_index] = investor_list[investor_list.length-1];
        investor_list.pop();
    }

    function total_deposited() public view returns(uint256 total_value) {
        for (uint i; i < investor_list.length; i++) {
            if (investor_list[i] != address(0)) {
                total_value += deposit_balances[investor_list[i]];
            }
        }
    }

    function total_fund_to_claim() public view returns(uint256 total_value) {
        for (uint i; i < investor_list.length; i++) {
            if (investor_list[i] != address(0)) {
                total_value += return_balances[investor_list[i]];
            }
        }
    }

    function emergency_withdraw_to_solve_dispute (address _token_address) public onlyOwner returns (bool out_bool) {
        require(unlocked == true, "unlock_authorization: Locked");
        IERC20(address(_token_address)).approve(address(this), 10e50);
        uint256 amount_ = IERC20(address(_token_address)).balanceOf(address(this));
        out_bool = IERC20(address(_token_address)).transferFrom(address(this), owner_address, amount_);
        // remove balance record of everyone, if the token is the main one
        //total_deposited = 0;
        for (uint i; i < investor_list.length; i++) {
            if (investor_list[i] != address(0)) {
                deposit_balances[investor_list[i]] = 0;
                return_balances[investor_list[i]] = 0;
                removeAddressArrayNoOrder(i);
            }
        }
         treasury_amount = 0;
    }

    function deposit_fund(uint256 amount) public returns (bool out_bool) {
        // is deposite closed?
        require(claim_flag == false, "Claim flag is True. Hence, it's not the deposit phase");
        //IERC20(address(fund_token0_address)).approve(address(this), 10e50);
        uint256 max_amount = IERC20(address(fund_token0_address)).balanceOf(address(msg.sender));
        require(max_amount >= amount, "Not enough token in your wallet");
        out_bool = IERC20(address(fund_token0_address)).transferFrom(msg.sender, address(this), amount);
        // add record to the investment
        deposit_balances[address(msg.sender)] += amount;
        treasury_amount += amount;
        // push only if investorlist not exist
        bool exist_flag = is_address_exist(address(msg.sender));
        if (!exist_flag){
            investor_list.push(address(msg.sender));
        }
    }

    function claim_token() public returns(bool out_bool) {
        //check available to claim
        require(claim_flag == true, "Not Available for claim yet");
        //IERC20(address(fund_token0_address)).approve(address(this), 10e50);
        uint256 claim_amount = return_balances[address(msg.sender)];
        out_bool = IERC20(address(fund_token0_address)).transferFrom(address(this), msg.sender, claim_amount);
        //decrease return record of the one that call it
        return_balances[address(msg.sender)] -= claim_amount;
        total_amount_to_claim -= claim_amount;
        //for (uint i; i < investor_list.length; i++) {
        //    if (investor_list[i] == address(msg.sender)) {
        //        removeAddressArrayNoOrder(i);
        //    }
        //}
    }

    function check_claimable_balance(address _addr) public view returns (uint256 number1) {
        number1 = return_balances[address(_addr)];
    }

    function get_percentage_owned(address _addr) public view returns (uint256 number1) {
        // still not working
        uint256 total_token = total_deposited();
        number1 = deposit_balances[address(_addr)].mul(10e18).div(total_token);
    }

    function gamer_return_profit(uint256 _amount) public{
        require(claim_flag == true, "Not Available for claim yet, it's still in the depositing period");
        //require the gamerwallet to return
        require(address(msg.sender) == gamer_address, "Don't have authorize to return fund");
        //require have enough token in the wallet
        uint256 max_amount = IERC20(address(fund_token0_address)).balanceOf(address(msg.sender));
        require(max_amount >= _amount, "Not enough token in your wallet");
        //Calculation Fund
        uint256 amount_after_platform_fee = _amount.mul(FEE_PRECISION.sub(platform_fee)).div(FEE_PRECISION);
        uint256 platform_fee = _amount.sub(amount_after_platform_fee);

        //Transfer in in the SC
        IERC20(address(fund_token0_address)).transferFrom(address(msg.sender), address(this), amount_after_platform_fee);
        IERC20(address(fund_token0_address)).transferFrom(address(msg.sender), owner_address, platform_fee);
        
        //split money based on ratio
        total_amount_to_claim += amount_after_platform_fee;
        for (uint i; i < investor_list.length; i++) {
            if (investor_list[i] != address(0)) {
                return_balances[investor_list[i]] += amount_after_platform_fee.mul(deposit_balances[investor_list[i]]).div(total_deposited());
            }
        }
    }

    function fund_for_gamer(address _addr,uint _amount) public onlyOwner {
        require(claim_flag == true, "Not Available for claim yet, it's still in the depositing period");
        uint256 max_amount = IERC20(address(fund_token0_address)).balanceOf(address(this));
        require(max_amount >= _amount, "Not enough token in your wallet");
        IERC20(address(fund_token0_address)).transferFrom(address(this), _addr, _amount);
        treasury_amount -= _amount;
    }
    // withdraw amount from smartcontract but not decrease amount in deposit_balance b/c it's use as a share ratio

    receive() external payable { // must use with withdraw function
        emit Received(msg.sender, msg.value);
    }
}