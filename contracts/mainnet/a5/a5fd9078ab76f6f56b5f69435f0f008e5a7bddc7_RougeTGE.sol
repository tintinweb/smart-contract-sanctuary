contract RGX {
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract RGE {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract RougeTGE {
    
    string public version = &#39;v1.1&#39;;
    
    address owner; 

    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    bool public fundingActive = true;

    function toggleFunding(bool _flag) onlyBy(owner) public {
        fundingActive = _flag;
    }

    uint public fundingStart;
    uint public fundingEnd;

    modifier beforeTGE() {
        require(fundingStart > now);
        _;
    }

    modifier TGEOpen() {
        require(fundingStart <= now && now < fundingEnd);
        require(fundingActive);
        _;
    }
    
    modifier afterTGE() {
        require(now >= fundingEnd);
        _;
    }

    function isFundingOpen() constant public returns (bool yes) {
        return(fundingStart <= now && now < fundingEnd && fundingActive);
    }

    mapping (address => bool) public kyc;
    mapping (address => uint256) public tokens;
    mapping (address => mapping (address => uint256)) public used;

    function tokensOf(address _who) public view returns (uint256 balance) {
        return tokens[_who];
    }

    uint8 public minFunding = 1; /* in finney */
    uint8 public decimals = 6;
    uint256 public total_distribution = 500000000 * 10**uint(decimals); /* Total RGE tokens to distribute during TGE (500m with 6 decimals) */

    struct Sale {
        uint256 funding; // original contribution in finney
        uint256 used;    // already used with bonus contribution in finney
        uint256 tokens;  // RGE tokens distribution
        bool presale;
    }

    uint256 public tokenPrice; /* in wei */

    constructor(
                uint _fundingStart,
                uint _fundingEnd,
                uint _tokenPrice
                ) public {
        owner = msg.sender;
        fundingStart = _fundingStart;
        fundingEnd = _fundingEnd;
        tokenPrice = _tokenPrice;
    }
    
    address rge; 

    address rgxa; 
    address rgxb; 
    address rgxd; 

    address rgx20; 
    address rgx15; 
    address rgx12; 
    address rgx9; 
    address rgx8; 
    address rgx7; 
    address rgx6; 
    address rgx5; 
    address rgx4; 
    address rgx3; 

    function init (
                   address _rge,
                   address _rgxa, address _rgxb, address _rgxd,
                   address _rgx20, address _rgx15, address _rgx12,
                   address _rgx9, address _rgx8, address _rgx7, address _rgx6, address _rgx5, address _rgx4, address _rgx3
                   ) onlyBy(owner) public {
        rge = _rge;
        rgxa = _rgxa; rgxb = _rgxb; rgxd = _rgxd; 
        rgx20 = _rgx20; rgx15 = _rgx15; rgx12 = _rgx12;
        rgx9 = _rgx9; rgx8 = _rgx8; rgx7 = _rgx7; rgx6 = _rgx6; rgx5 = _rgx5; rgx4 = _rgx4; rgx3 = _rgx3;
    }
    
    event Distribute(address indexed buyer, uint256 value);

    function () payable TGEOpen() public { 

        require(msg.sender != owner);

        Sale memory _sale = Sale({
            funding: msg.value / 1 finney, used: 0, tokens: 0, presale: false
        });

        require(_sale.funding >= minFunding);

        /* distribution with RGX discounts */
        
        _sale = _with_RGXBonus(_sale, rgxa, 20, 1);
        _sale = _with_RGXBonus(_sale, rgxb, 11, 1);
        _sale = _with_RGXBonus(_sale, rgxd, 5, 4);

        _sale = _with_RGXToken(_sale, rgx20, 20, 1);
        _sale = _with_RGXToken(_sale, rgx15, 15, 1);
        _sale = _with_RGXToken(_sale, rgx12, 12, 1);
        _sale = _with_RGXToken(_sale, rgx9, 9, 1);
        _sale = _with_RGXToken(_sale, rgx8, 8, 1);
        _sale = _with_RGXToken(_sale, rgx7, 7, 1);
        _sale = _with_RGXToken(_sale, rgx6, 6, 1);
        _sale = _with_RGXToken(_sale, rgx5, 5, 1);
        _sale = _with_RGXToken(_sale, rgx4, 4, 1);
        _sale = _with_RGXToken(_sale, rgx3, 3, 1);

        /* standard tokens distribution */
        
        if ( _sale.funding > _sale.used ) {

            uint256 _available = _sale.funding - _sale.used;
            _sale.used += _available;
            _sale.tokens += _available * 1 finney * 10**uint(decimals) / tokenPrice;
            
        }
        
        /* check if enough tokens and distribute tokens to buyer */
        
        require(total_distribution >= _sale.tokens); 

        total_distribution -= _sale.tokens;
        tokens[msg.sender] += _sale.tokens;
        emit Distribute(msg.sender, _sale.tokens);

    }
    
    function _with_RGXBonus(Sale _sale, address _a, uint8 _multiplier, uint8 _divisor) internal returns (Sale _result) {

        RGX _rgx = RGX(_a);

        uint256 rgxBalance = _rgx.balanceOf(msg.sender);

        if ( used[_a][msg.sender] < rgxBalance && _sale.funding > _sale.used ) {

            uint256 _available = rgxBalance - used[_a][msg.sender];

            if ( _available > _sale.funding - _sale.used ) {
                _available = _sale.funding - _sale.used;
            }

            _sale.used += _available;
            _sale.tokens += _available * 1 finney * 10**uint(decimals) / tokenPrice * _multiplier / _divisor;
            used[_a][msg.sender] += _available;
        }

        return _sale;
    }

    function _with_RGXToken(Sale _sale, address _a, uint8 _multiplier, uint8 _divisor) internal returns (Sale _result) {

        if ( _sale.presale ) {
            return _sale;
        }
        
        RGX _rgx = RGX(_a);

        uint256 rgxBalance = _rgx.balanceOf(msg.sender);

        if ( used[_a][msg.sender] < rgxBalance ) {

            uint256 _available = rgxBalance - used[_a][msg.sender];

            _sale.tokens += _available * 1 finney * 10**uint(decimals) / tokenPrice * (_multiplier - 1) / _divisor;
            used[_a][msg.sender] += _available;
            _sale.presale = true;
        }

        return _sale;
    }

    function toggleKYC(address _who, bool _flag) onlyBy(owner) public {
        kyc[_who]= _flag;
    }
    
    function revertAML(address _who) onlyBy(owner) public {
        total_distribution += tokens[_who];
        tokens[_who] = 0;
    }

    function withdraw() public returns (bool success) {

        require(msg.sender != owner); 
        
        // no verification if enough tokens => done in payable already
        
        require(tokens[msg.sender] > 0);
        require(kyc[msg.sender]); 
        
        RGE _rge = RGE(rge);
        
        if ( _rge.transfer(msg.sender, tokens[msg.sender]) ) {
            tokens[msg.sender] = 0;
            return true;
        } 
        
        return false;
        
    }
    
    function withdrawFunding() onlyBy(owner) public {
        msg.sender.transfer(address(this).balance);
    }
    
    function kill() onlyBy(owner) public {
        selfdestruct(owner);
    }

}