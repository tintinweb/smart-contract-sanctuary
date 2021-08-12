/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20Metadata is IBEP20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract BEP20 is Context, IBEP20, IBEP20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract BEP20Token is BEP20("Vudi", "Vudi", 18) {
    struct Presale {
        uint256 share_percent;
        uint256 unlocked_presale_fund;
        bool is_started;
        uint256 sold_amount;
        uint256 distributed_in_presale;
        address presale_fund_address;
        uint256 token_rate;
    }
    /*
    *   Token Rate is the amount of token with decimals will distributed per BNB.
    *
    */
    
    /*
    *_____________________________________________
    * Making struct for the locked fund wallets.
    *--------------------------------------------
    */
    
    struct Locked {
        uint256 locked_percent;
        address[] members;
        uint256 locked_timestamp;
    }
    
    Locked public team_locked;
    
    Locked public ecosystem_locked;
    
    struct AIlocked {
        uint256 locked_percent;
        address[] members;
        uint256 locked_timestamp;
    }
    
    AIlocked[3] public ai_locked;
    
    Presale[3] public presales;

    struct PublicSale {
        uint256 public_sale_percent;
        address public_sale_wallet;
    }

    PublicSale[5] public public_sale;
    
    
    constructor() {
        /*
        *_____________________________________________
        * assigning Values to the Presale mapping
        *--------------------------------------------
        */
        presales[0] = Presale(60, 20, false, 0, 0, 0xa53FfBdfC9A58f192b6569744c88386b094B0767, 10000000);
        presales[1] = Presale(70, 20, false, 0, 0, 0x12D78b3084a2a7E55E549260a38bD762CfD374cc, 10000000);
        presales[2] = Presale(70, 20, false, 0, 0, 0x344519a1767f16Dd3bF2D1d0793358a6bbCe1013, 10000000);
        
        /*
        *_____________________________________________
        * assigning Values to the Locked wallets.
        *--------------------------------------------
        */
        team_locked.locked_percent = 5;
        address[1] memory team_locked_members;
        team_locked_members[0] = 0xFb3479E43Fd3CAD9847B35393200E29b0d77d65d;
        team_locked.members= team_locked_members;
        team_locked.locked_timestamp = block.timestamp + 31536000;
        
        ecosystem_locked.locked_percent = 15;
        address[1] memory ecosystem_locked_members;
        ecosystem_locked_members[0] = 0xcaFD0B0BfC54c72D77238319393BdD91483C4999;
        ecosystem_locked.members = ecosystem_locked_members;
        ecosystem_locked.locked_timestamp = block.timestamp + 31536000;
        
        ai_locked[0].locked_percent = 5;
        address[1] memory ai_locked_members_one;
        ai_locked_members_one[0] = 0x7B8C97A1D9b64529B92aBd0a7c4C2EAD236c4DCE;
        ai_locked[0].members = ai_locked_members_one;
        ai_locked[0].locked_timestamp = block.timestamp;
        
        ai_locked[1].locked_percent = 5;
        address[1] memory ai_locked_members_two;
        ai_locked_members_two[0] = 0xEE029ebA335046cAd6D18f19AA00a2FB7aEa941e;
        ai_locked[1].members = ai_locked_members_two;
        ai_locked[1].locked_timestamp = block.timestamp + 31536000;
        
        ai_locked[2].locked_percent = 10;
        address[1] memory ai_locked_members_three;
        ai_locked_members_three[0] = 0x286FDAa0735420775471A6368111Ee8eeC38418d;
        ai_locked[2].members = ai_locked_members_three; 
        ai_locked[2].locked_timestamp = block.timestamp + 47304000;
        
        /*
        *_____________________________________________
        * assigning Values to the Public Sale mapping
        *--------------------------------------------
        */
        public_sale[0] = PublicSale(11, 0x4Dc817014E1c8E99bEb3eBAb3DeeA6567151a47C);
        public_sale[1] = PublicSale(11, 0x795C9B4870C215ae7a61a906cf3B57C3fB4B2C5d);
        public_sale[2] = PublicSale(12, 0x55F610b326c5Bc918C3C02F2dc3B3EFd2fFA5008);
        public_sale[3] = PublicSale(12, 0xEFf9ad4587343B538e50bCa2517f8B9EcbA204A7);
        public_sale[4] = PublicSale(12, 0x7e084c3fcB86618eb24F64EFb52d2f32EE30FeA7);

        /*
        * ___________________________________________
        * Minting tokens to all the address.
        * --------------------------------------------
        */
        uint256 _decimals_ = decimals();
        uint256 _supply = 1 * 10**9 * 10**_decimals_;
        
        /*
        * ___________________________________________
        * Miniting to the locked Addresses.
        * --------------------------------------------
        */
            // Minting to the team wallet. 
            uint256 total_for_team = (_supply*team_locked.locked_percent)/100;
            for(uint i=0; i < team_locked.members.length; i++){
                _mint(team_locked.members[i], total_for_team/team_locked.members.length);
            }
            
            // Minting to the ecosystem wallet.
            uint256 total_for_ecosystem = (_supply*ecosystem_locked.locked_percent)/100;
            for(uint i=0; i < ecosystem_locked.members.length; i++){
                _mint(ecosystem_locked.members[i], total_for_ecosystem/ecosystem_locked.members.length);
            }
            
            // Minting to the AI_one.
            for(uint i =0; i< ai_locked.length; i++){
                uint256 total_for_ai_one = (_supply*ai_locked[i].locked_percent)/100;
                for(uint j=0; j < ai_locked[i].members.length; j++){
                    _mint(ai_locked[i].members[j], total_for_ai_one/ai_locked[i].members.length);
                }
            }
            
        /*
        * ___________________________________________
        * Miniting to the unlocked Addresses.
        * --------------------------------------------
        */
            // Presale Minting.
            for(uint i=0; i < presales.length; i++){
                uint256 total_presale_mint = ((_supply*presales[i].share_percent) / 10000);
                _mint(presales[i].presale_fund_address, total_presale_mint);
            }
            
            // Public Sale minting.
            for(uint i=0; i < public_sale.length; i++){
                uint256 total_public_sale_mint = (_supply*public_sale[i].public_sale_percent)/100;
                _mint(public_sale[i].public_sale_wallet, total_public_sale_mint);
            }
            
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        
        /*
        * ___________________________________________
        * Checking the locked addresses.
        * --------------------------------------------
        */
            // for team_locked check.
            for(uint i=0; i < team_locked.members.length; i++ ){
                msg.sender==team_locked.members[i]? require(team_locked.locked_timestamp < block.timestamp, "BEP20: Time Locked -> wait for the locked_time."):();
            }
            
            // for ecosystem_locked check.
            for(uint i=0; i < ecosystem_locked.members.length; i++ ){
                msg.sender==ecosystem_locked.members[i]? require(ecosystem_locked.locked_timestamp < block.timestamp, "BEP20: Time Locked -> wait for the locked_time."):();
            }
            
            // for AI locked check.
            for(uint i =0; i< ai_locked.length; i++){
                for(uint j=0; j < ai_locked[i].members.length; j++){
                    msg.sender==ai_locked[i].members[j]? require(ai_locked[i].locked_timestamp < block.timestamp, "BEP20: Time Locked -> wait for the locked_time."):();
                }
            }
        

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function airdrop_for_presale(address[] memory _address_array, uint256[] memory _amount_array_with_decimals, uint8 _presale_index) public {
        require(msg.sender==presales[_presale_index].presale_fund_address, "BEP20: You are not the presale owner");
        uint256 total_distributed = 0;
        for(uint i=0; i < _address_array.length; i++){
            _transfer(msg.sender, _address_array[i], _amount_array_with_decimals[i]);
            total_distributed += _amount_array_with_decimals[i];
        }
        
        presales[_presale_index].distributed_in_presale += total_distributed;
        
    }
    
    function Airdrop(address[] memory _address_array, uint256[] memory _amount_array_with_decimals) public {
        for(uint i=0; i < _address_array.length; i++){
            transfer(_address_array[i], _amount_array_with_decimals[i]);
        }
    }
    
    function presale_one() view public returns(Presale memory) {
        return presales[0];
    }
    
    function presale_two() view public returns(Presale memory) {
        return presales[1];
    }
    
    function presale_three() view public returns(Presale memory) {
        return presales[2];    
    }
    
    function setTokenRate(uint256 _token_amount_per_bnb_in_decimals, uint8 _presale_index) public {
        require(msg.sender==presales[_presale_index].presale_fund_address, "BEP20: You are not the presale owner");
        /*
        * Setting the token Rate Make sure that you have put the token value with the decimals.
        */
        
        presales[_presale_index].token_rate = _token_amount_per_bnb_in_decimals;
        
    }
    
    function buyToken(uint8 _presale_index) public payable {
        require(presales[_presale_index].is_started == true, "BEP20: Presale is not started yet.");
        require(msg.value>0, "BEP20: value must be larger then zero");
        /*
        * --------------------------------------------
        * Checking for the presale fund avaiable.
        * ___________________________________________
        */
        
        uint256 presale_share_percent = presales[_presale_index].share_percent;
        uint256 supply = totalSupply();
        uint256 total_presale_fund = (presale_share_percent*supply)/100;
        uint256 unlocked_presale_fund = (presales[_presale_index].unlocked_presale_fund * total_presale_fund)/100;
        uint256 remaining_presale_fund = unlocked_presale_fund - presales[_presale_index].distributed_in_presale;
        
        uint256 token_transfer_amount = (msg.value*presales[_presale_index].token_rate)/10**18 ;
        require(token_transfer_amount >= remaining_presale_fund, "BEP20: No Balance remaining to meet your requirements.");
        
        payable(presales[_presale_index].presale_fund_address).transfer(msg.value);
        _transfer(presales[_presale_index].presale_fund_address, msg.sender, token_transfer_amount);
        
        presales[_presale_index].sold_amount += token_transfer_amount;
    }
    
    function startPresale(uint8 _presale_index) public {
        require(msg.sender==presales[_presale_index].presale_fund_address, "BEP20: Only the presale owner allowed to start Presale.");
        presales[_presale_index].is_started = true;
    }
    
    function endPresale(uint8 _presale_index) public {
        require(msg.sender==presales[_presale_index].presale_fund_address, "BEP20: Only the presale owner allowed to End Presale.");
        presales[_presale_index].is_started = false;
    }
    
}