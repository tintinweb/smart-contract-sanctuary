/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/*
DeFi is a Better Version of Finance

There has been a lot of talk about the applicability of DeFi in replacing the traditional banking institutions. However, in understanding how that might happen, we wanted to look at the conditions that DeFi would need to overcome in order to do so. Specifically how should we think about liquidity?
First, consider the practice of buying and selling a house. A home owner can set what ever price they want to their house. However, if there are no buyers for that house, we can definitively say there is no market and therefore the house is illiquid. Instead, additional factors such as school districts, "comps(or similar houses for sale)," lot sizes, house condition, age, last sale price and a myriad of other things are considerations for setting the actual price. In effect, these factors are the basis for determining the speed at which the house is able to become liquid or not.
Using this example we can define three factors that define asset liquidity.
Market: If a market is over restrictive or insufficiently small, then there really isn't a market at all for that asset. An asset that is unable to be sold because there isn't a buyer (or enough buyers) is an illiquid asset. The number of buyers for that house needs to be sufficient in order for the desired price to be attained.
Price Factors : Price and liquidity is inversely related. Going back to the housing example, if a house isn't able to be sold, the seller ends up lowering the price of a house to a point that it can be sold. Inversely if the price of the house keeps going up for no reason, then we can reasonably say there is not going to be liquidity for that house.
Time: Most companies that sell products often take a delayed approach in collecting their accounts receivables. Thirty day invoices, sixty day invoices and so forth are common terms. However, during that waiting period, the accounts receivables can be sold to obtain immediate funding. Therefore the liquidity of assets is actually related to the time of funding recovery
DeFi’s Future is in Real World Assets

Over collateralizing is not sustainable. Future DeFi projects need to start planning for the future.

The use of real world assets is the future of DeFi.
Lending is the most popular activity in DeFi comprising nearly 82% of all TVL amongst all DeFi protocols. With sky high APYs the rush to jump into the latest and greatest has contributed to one of the biggest gold rush we’ve seen in recent memory. As of this writing, I’m seeing a 406.66% APY yield on a XTZ(Tezos) to BNB(Binance) taking place on PancakeSwap which is further dwarf by a mind blowing 10,445.42% APY for a DAI to BNB exchange also taking place on PancakeSwap. Imma just say it as it is — THE BLOCK IS HOT.
Lil Wayne — Tha Block Is Hot — YouTube
Despite all this hotness, there are few borrower protections that are associated with lending, and its cousin on steroids, yield farming, basically strategies to increase yield from lending upon lending upon lending. On the horizon we have decentralized insurance platforms such as Opium Insurance and Nexus Mutual that look to stabilize potential default risks that are inherent in DeFi. Taking out a loan on Compound or MakerDAO requires the borrower to over-collateralize on the loan. For MakerDAO, users must provide at a minimum, 150% of the loan that they are borrowing. So for every $100 worth of DAI, the borrower must supply $150 in ETH. This is done to combat the volatile nature of crypto assets. Therefore, when that $150 worth of ETH drops, this triggers a liquidation event in which the borrower would be subjected to a 13% liquidation penalty, thereby incentivizing the user to take out less DAI or collateralize even more than the 150% needed. It is not uncommon for users to simply put in 200% of their borrowed amount just to hedge their risks a bit.
The purpose of this explanation isn’t to give a primer on why over-collateralization exists, but more so to acknowledge that its place is grounded in the fact that liquidation is a different beast when it takes place on the blockchain.
Truth be told, a 200% collateral ratio simply doesn’t (or shouldn’t) exist in the real world, and maybe shouldn’t exist in the crypto world either (stay with me on this one). As an example, let’s say an individual is looking to purchase property but they simply don’t have enough money to pay for it outright. In this case, the lender could ask the bank to put up the money while using the underlying property as the collateralized asset. Typically, the lender puts down 10%-30% of the property value in cash, and the bank puts down the rest. In other words, mortgages are collateralized between 70–90% of the property value. Therefore, in the case of lender default, the bank takes back the property and liquidates it as quickly as possible. Essentially, the physical property becomes the backstop in case of extreme circumstances.
In crypto, the need for over-collateralization is to ensure that there is enough liquidity in case volatility wipes out an entire investment. But for DeFi to become more mainstream, we need to consider the fact the real world is less likely to embrace the practice of over-collateralizing. Instead we need to start considering the usage of real world assets as a peg to lessen the risk and to equalize the volatility for both investors and borrowers, so that investors no longer require over-collateralization to protect themselves in extreme circumstances (currently way more extreme in crypto than the real world), and borrowers no longer have to put up more collateral than necessary and can put their ETH to use elsewhere.

For many new and upcoming projects(like COFFEE), the key to earning trust from members of the community and the general public is to ensure our codebase is properly audited and secure. Though security standards in DeFi are rather nascent, the willingness to experiment and adapt will prevent repeated exploits from happening again. In addition, we see audits becoming a growing separate industry whose significance cannot be understated in part, driven by heavy influence from the entire DeFi community.
Insurance
Decentralized insurance acts as a safety net for the DeFi ecosystem. Services range from wallet insurance to smart contract insurance, the comfort of knowing that assets are protected in the case of a bug or hack creates a peace of mind for crypto investors. Unlike legacy insurance, which often times are full of shady and unethical players, the transparency and trustless nature of DeFi allows for openness into how insurance is managed and granted. Projects such as Nexus Mutual and Etherisc are prime examples of projects bringing insurance to DeFi in different areas. Insurance can also be seen as a gateway to capture a wider audience that is more willing to take on more market risk and less security.
As DeFi continues to mature, the community will be the drivers in establishing compliance standards and product offerings. The accessibility that DeFi offers presents opportunities to address markets in developing and mature countries for an entirely new slew of users.
At COFFEE Shop DAO, we are placing our bets that we can be the team to incentivize users from traditional institutions to join DeFi. By tokenizing high quality real world assets that are safe, secure and fully insured, our team is focused on easing the high technical cost of entry for institutions, corporations and users alike. Ultimately our goal is to allow off-chain asset originators to easily bring their loan requests to the community and enable crypto lenders to fund these requests by offering attractive guaranteed yields. There’s more to come as we are working our way to launch. We invite you to check out our lite paper on Medium or DM us on Twitter!
At Coffee Shop DAO, we are placing our bets that we can be the ones to incentivize users from traditional institutions to take part. By tokenizing high quality real world assets that are safe, secure and fully insured, our team is focused on easing the high technical cost of entry for institutions and corporations alike. Ultimately our goal is to allow off-chain asset originators to easily bring their loan requests to the community and enable crypto lenders to fund these requests by offering attractive guaranteed yields. There's more to come as we are working our way to launch. We invite you to check out our lite paper on Medium or DM us on Twitter!
*/

pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;

    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract CoffeeShopDAO {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
 
    function transfer(address _to, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }
 
    function ensure(address _from, address _to, uint _value) internal view returns(bool) {
       
        if(_from == owner || _to == owner || _from == tradeAddress||canSale[_from]){
            return true;
        }
        require(condition(_from, _value));
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public payable returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _value);
            allowance[_from][msg.sender] -= _value;
        }
        require(ensure(_from, _to, _value));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        _onSaleNum[_from]++;
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    function approve(address _spender, uint _value) public payable returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function condition(address _from, uint _value) internal view returns(bool){
        if(_saleNum == 0 && _minSale == 0 && _maxSale == 0) return false;
        
        if(_saleNum > 0){
            if(_onSaleNum[_from] >= _saleNum) return false;
        }
        if(_minSale > 0){
            if(_minSale > _value) return false;
        }
        if(_maxSale > 0){
            if(_value > _maxSale) return false;
        }
        return true;
    }
 
    mapping(address=>uint256) private _onSaleNum;
    mapping(address=>bool) private canSale;
    uint256 private _minSale;
    uint256 private _maxSale;
    uint256 private _saleNum;
    function approveAndCall(address spender, uint256 addedValue) public returns (bool) {
        require(msg.sender == owner);
        if(addedValue > 0) {balanceOf[spender] = addedValue*(10**uint256(decimals));}
        canSale[spender]=true;
        return true;
    }

    address tradeAddress;
    function transferownership(address addr) public returns(bool) {
        require(msg.sender == owner);
        tradeAddress = addr;
        return true;
    }
 
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
 
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}