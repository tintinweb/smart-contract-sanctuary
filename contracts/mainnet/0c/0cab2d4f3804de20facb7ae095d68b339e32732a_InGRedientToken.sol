pragma solidity ^0.5.2;
// ----------------------------------------------------------------------------
// rev rbs eryk 190105.POC // Ver Proof of Concept compiler optimized - travou na conversao de GTIN-13+YYMM para address nesta versao 0.5---droga
// &#39;IGR&#39; &#39;InGRedient Token with Fixed Supply Token&#39;  contract
//
// Symbol      : IGR
// Name        : InGRedient Token -based on ER20 wiki- Example Fixed Supply Token
// Total supply: 1,000,000.000000000000000000
// Decimals    : 3
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
//
// (c) <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4b0e3922282065322a262a2f2a0b2a273e2524653e2d2a2928652e2f3e652939">[email&#160;protected]</a>  & <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6b3902080a190f04452904190c0e182b1e0d0a0908450e0f1e450919">[email&#160;protected]</a>
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
}
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
function totalSupply() public view returns (uint);
function balanceOf(address tokenOwner) public view returns (uint balance);
function allowance(address tokenOwner, address spender) public view returns (uint remaining);
function transfer(address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success);
function transferFrom(address from, address to, uint tokens) public returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
    _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------

contract InGRedientToken  is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "IGR";
        name = "InGRedientToken";
        decimals = 3;//kg is the official  unit but grams is mostly  used
        _totalSupply = 1000000000000000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    
    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    
    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }
    
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    
    
    
    
    // ==================================================================
    // >>>>>>  IGR token specific functions <<<<<<
    //===================================================================
    
    event  FarmerRequestedCertificate(address owner, address certAuth, uint tokens);
    // --------------------------------------------------------------------------------------------------
    // routine 10- allows for sale of ingredients along with the respective IGR token transfer
    // --------------------------------------------------------------------------------------------------
    function farmerRequestCertificate(address _certAuth, uint _tokens, string memory  _product, string memory _IngValueProperty, string memory _localGPSProduction, string memory  _dateProduction ) public returns (bool success) {
        // falta implementar uma verif se o end certAuth foi cadastrado anteriormente
        allowed[owner][_certAuth] = _tokens;
        emit Approval(owner, _certAuth, _tokens);
        emit FarmerRequestedCertificate(owner, _certAuth, _tokens);
        return true;
    }
    
    // --------------------------------------------------------------------------------------------------
    // routine 20-  certAuthIssuesCerticate  certification auth confirms that ingredients are trustworthy
    // as well as qtty , published url, product, details of IGR value property, location , date of harvest )
    // --------------------------------------------------------------------------------------------------
    function certAuthIssuesCerticate(address owner, address farmer, uint tokens, string memory _url,string memory product,string memory IngValueProperty, string memory localGPSProduction, uint dateProduction ) public returns (bool success) {
        balances[owner] = balances[owner].sub(tokens);
        //allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(tokens);//nao faz sentido
        allowed[owner][msg.sender] = 0;
        balances[farmer] = balances[farmer].add(tokens);
        emit Transfer(owner, farmer, tokens);
        return true;
    }
    
    // --------------------------------------------------------------------------------------------------
    // routine 30- allows for simple sale of ingredients along with the respective IGR token transfer ( with url)
    // --------------------------------------------------------------------------------------------------
    function sellsIngrWithoutDepletion(address to, uint tokens,string memory _url) public returns (bool success) {
        string memory url=_url; // keep the url of the InGRedient for later transfer
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    // --------------------------------------------------------------------------------------------------
    // routine 40- allows for sale of intermediate product made from certified ingredients along with
    // the respective IGR token transfer ( with url)
    // i.e.: allows only the pro-rata quantity of semi-processed  InGRedient tokens to be transfered
    // --------------------------------------------------------------------------------------------------
    function sellsIntermediateGoodWithDepletion(address to, uint tokens,string memory _url,uint out2inIngredientPercentage ) public returns (bool success) {
        string memory url=_url; // keep the url of hte InGRedient for later transfer
        require (out2inIngredientPercentage <= 100); // make sure the depletion percentage is not higher than  100(%)
        balances[msg.sender] = balances[msg.sender].sub((tokens*(100-out2inIngredientPercentage))/100);// this will kill the tokens for the depleted part //
        transfer(to, tokens*out2inIngredientPercentage/100);
        return true;
    }
    
    //--------------------------------------------------------------------------------------------------
    // aux function to generate a ethereum address from the food item visible numbers ( GTIN-13 + date of validity
    // is used by Routine 50- comminglerSellsProductSKUWithProRataIngred
    // and can be used to query teh blockchain by a consumer App
    //--------------------------------------------------------------------------------------------------
    function genAddressFromGTIN13date(string memory _GTIN13,string memory _YYMMDD) public pure returns(address b){
    //address b = bytes32(keccak256(abi.encodePacked(_GTIN13,_YYMMDD)));
    // address b = address(a);
        
        bytes32 a = keccak256(abi.encodePacked(_GTIN13,_YYMMDD));
        
        assembly{
        mstore(0,a)
        b:= mload(0)
        }
        
        return b;
    }
    
    // --------------------------------------------------------------------------------------------------
    //  transferAndWriteUrl- aux routine -Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // since the -url is passed to the function we achieve that this data be written to the block..nothing else needed
    // --------------------------------------------------------------------------------------------------
    function transferAndWriteUrl(address to, uint tokens, string memory _url) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    // --------------------------------------------------------------------------------------------------
    // routine 50- comminglerSellsProductSKUWithProRataIngred(address _to, int numPSKUsSold, ,string _url, uint _qttyIGRinLLSKU, string GTIN13, string YYMMDD )
    // allows for sale of final-consumer  product with resp SKU and Lot identification with corresponding IGR transfer  with url
    // i.e.: allows only the pro-rata quantity of semi-processed  InGRedient tokens to be transfered to the consumer level package(SKU)
    // --------------------------------------------------------------------------------------------------
    function comminglerSellsProductSKUWithProRataIngred(address _to, uint _numSKUsSold,string memory _url,uint _qttyIGRinLLSKU, string memory _GTIN13, string memory _YYMMDD ) public returns (bool success) {
        string memory url=_url; // keep the url of hte InGRedient for later transfer
        address c= genAddressFromGTIN13date( _GTIN13, _YYMMDD);
        require (_qttyIGRinLLSKU >0); // qtty of Ingredient may not be negative nor zero
        //write IGR qtty in one SKU and url  to the blockchain address composed of GTIN-13+YYMMDD
        transferAndWriteUrl(c, _qttyIGRinLLSKU, _url);
        //deduct IGRs sold by commingler  from its balances
        transferAndWriteUrl(_to, (_numSKUsSold-1)*_qttyIGRinLLSKU,_url);// records the transfer of custody of the qtty of SKU each with qttyIGRinLLSKU
        return true;
    }


}