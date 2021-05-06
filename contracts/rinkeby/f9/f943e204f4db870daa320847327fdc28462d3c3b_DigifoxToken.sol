/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

/* Low-level code for DGF token, consider refactoring w/ OpenZeppelin */
pragma solidity 0.8.3;

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

contract Token {

    function balanceOf(address _owner) virtual public returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) virtual public returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success) {}
    function approve(address _spender, uint256 _value) virtual public returns (bool success) {}
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) override public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) override view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner.");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner cannot be 0x0.");
        require(newOwner != address(1), "Ownable: new owner cannot be 0x1.");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Vesting {
    function vest(uint256 amount, uint256 blocksUntilCompleted) external virtual;
    function withdraw() external virtual returns (uint256 withdrawn);
    function getOwner() external virtual view returns (address _owner);
}
// Have to import vesting interface here

contract DigifoxToken is Ownable, StandardToken {
    using SafeMath for uint256;
    
    /** Token Constants, includes Decimals and Supply metrics **/
    string  public constant name            = "Digifox Token";
    string  public constant symbol          = "DGF";
    uint256 public constant decimals        = 18;
    uint256 public constant totalSupply     = 10000000 * 10**decimals;
    mapping(address => uint256) public tiers;
    
    // Distribution wallets, smart contracts for fair distribution of DGF
    address private constant earlyAdopterDistributionWallet         = address(0x0); // MINTABLE (use Minting.sol)
    address private constant liquidityProviderDistributionWallet    = address(0x0); // MINTABLE (use Minting.sol)
    address private constant bonusDistributionWallet                = address(0x0); // MAYBE DON'T MAKE MINTABLE (use Minting.sol) Affiliate Program (track affiliate wallets & get a % of the )
    address private constant communityDistributionWallet            = address(0x0); // Vested for 4 years (9553030 blocks, use Vesting.sol)
    address private constant educationDistributionWallet            = address(0x0); // Vested for 4 years (9553030 blocks, use Vesting.sol)
    address private constant wefunderDistributionWallet             = address(0x0); // NOT VESTED! Directly airdrop to a list of wallets using MultiSender
    address private constant earlyInvestorsDistributionWallet       = address(0x178f8853Aac781d08392Af1Dab70B791FDcAa274); // NOT VESTED! Uniswap-style airdrop (use Airdrop.sol)
    address private constant partnersDistributionWallet             = address(0x0); // NOT VESTED 
    address private constant ambassadorsDistributionWallet          = address(0x0); // NOT VESTED
    address private constant employeeDistributionWallet             = address(0x0); // NOT VESTED
    address private constant advisorDistributionWallet              = address(0x0); // NOT VESTED
    address private constant reserveWallet                          = address(0x0); // Vested for 4 years (9553030 blocks, use Vesting.sol), 1% available upon launch
    
    // Distribution amounts per wallet
    uint256 private earlyAdopterDistributionAmount                  = totalSupply.div(4);
    uint256 private liquidityProviderDistributionAmount             = totalSupply.div(20);
    uint256 private bonusDistributionAmount                         = totalSupply.div(20);
    uint256 private communityDistributionAmount                     = totalSupply.div(50);
    uint256 private educationDistributionAmount                     = totalSupply.div(100);
    uint256 private wefunderDistributionAmount                      = totalSupply.div(100);
    uint256 private earlyInvestorsDistributionAmount                = totalSupply.div(100);
    uint256 private partnersDistributionAmount                      = totalSupply.div(50).mul(9);
    uint256 private ambassadorsDistributionAmount                   = totalSupply.div(50);
    uint256 private employeeDistributionAmount                      = totalSupply.div(50).mul(9);
    uint256 private advisorDistributionAmount                       = totalSupply.div(50);
    uint256 private reserveWalletAmountInitialUnlocked              = totalSupply.div(5).div(100);
    uint256 private reserveWalletAmount                             = totalSupply.div(5).sub(reserveWalletAmountInitialUnlocked);

    // Various maintenance variables
    bool    private vestingStarted = false;
    uint256 private blocksToVest = 9553030;
    address private minters;    // needed?

    
    constructor() {
        _owner = msg.sender;
        
        
        // 25% goes toward early adopter program
        transferFrom(address(0x0), earlyAdopterDistributionWallet, earlyAdopterDistributionAmount);
        
        // 5% goes toward liquidity provider program
        transferFrom(address(0x0), liquidityProviderDistributionWallet, liquidityProviderDistributionAmount);
        
        // 5% goes toward referral bonus program
        transferFrom(address(0x0), bonusDistributionWallet, bonusDistributionAmount);
        /*
        emit Transfer(address(0x0), bonusDistributionWallet, bonusDistributionAmount);
        balances[bonusDistributionWallet] += bonusDistributionAmount;
        
        // 2% goes toward community development fund
        emit Transfer(address(0x0), communityDistributionWallet, communityDistributionAmount);
        balances[communityDistributionWallet] += communityDistributionAmount;
        
        // 1% goes toward education grant program
        emit Transfer(address(0x0), educationDistributionWallet, educationDistributionAmount);
        balances[educationDistributionWallet] += educationDistributionAmount;
        
        // 1% goes toward the wefunder rewards program
        emit Transfer(address(0x0), wefunderDistributionWallet, wefunderDistributionAmount);
        balances[wefunderDistributionWallet] += wefunderDistributionAmount;
        
        // 1% goes toward the early investor rewards program
        emit Transfer(address(0x0), earlyInvestorsDistributionWallet, earlyInvestorsDistributionAmount);
        balances[earlyInvestorsDistributionWallet] += earlyInvestorsDistributionAmount;
        
        // 18% goes toward strategic partnerships
        emit Transfer(address(0x0), partnersDistributionWallet, partnersDistributionAmount);
        balances[partnersDistributionWallet] += partnersDistributionAmount;
        
        // 2% goes toward ambassadors
        emit Transfer(address(0x0), ambassadorsDistributionWallet, ambassadorsDistributionAmount);
        balances[ambassadorsDistributionWallet] += ambassadorsDistributionAmount;
        
        // 18% goes toward the employee fund
        emit Transfer(address(0x0), employeeDistributionWallet, employeeDistributionAmount);
        balances[employeeDistributionWallet] += employeeDistributionAmount;
        
        // 2% goes toward advisors
        emit Transfer(address(0x0), advisorDistributionWallet, advisorDistributionAmount);
        balances[advisorDistributionWallet] += advisorDistributionAmount;
        
        /* TODO: Causing compiler errors...
        // 20% goes to a company reserve, 1% unlocked immediately. 
        emit Transfer(address(0x0), Vesting(reserveWallet).getOwner(), reserveWalletAmountInitialUnlocked);
        emit Transfer(address(0x0), reserveWallet, reserveWalletAmount);
        balances[Vesting(reserveWallet).getOwner()] += reserveWalletAmountInitialUnlocked;
        balances[reserveWallet] += reserveWalletAmount;
        */
    }
    
    /***********************************************************************
        Function:   circulatingSupply()
        Args:       None
        Returns:    uint256 _circulatingSupply the current circulating supply.
        Notes:      A view for easy getting of the current DGF token supply.
    ***********************************************************************/
    
    function circulatingSupply() public view returns (uint256 _circulatingSupply) {
        // Returns the supply minus any balances from the premined wallets
        return totalSupply.sub(
                balanceOf(earlyAdopterDistributionWallet)).sub(
                balanceOf(liquidityProviderDistributionWallet)).sub(
                balanceOf(bonusDistributionWallet)).sub(
                balanceOf(communityDistributionWallet)).sub(
                balanceOf(educationDistributionWallet)).sub(
                balanceOf(wefunderDistributionWallet)).sub(
                balanceOf(earlyInvestorsDistributionWallet)).sub(
                balanceOf(partnersDistributionWallet)).sub(
                balanceOf(ambassadorsDistributionWallet)).sub(
                balanceOf(employeeDistributionWallet)).sub(
                balanceOf(advisorDistributionWallet)).sub(
                balanceOf(reserveWallet));
    }
    
    /***********************************************************************
        Function:   startVesting()
        Args:       None
        Returns:    None
        Notes:      Used to begin the vesting process of certain wallets once 
                    tokens have been transferred to distribution wallets.
    ***********************************************************************/
    
    function startVesting() public onlyOwner {
        require(!vestingStarted);
        vestingStarted = true;
        
        Vesting(communityDistributionWallet).vest(communityDistributionAmount, blocksToVest);
        Vesting(educationDistributionWallet).vest(educationDistributionAmount, blocksToVest);
        Vesting(reserveWallet).vest(reserveWalletAmount, blocksToVest);
    }
}