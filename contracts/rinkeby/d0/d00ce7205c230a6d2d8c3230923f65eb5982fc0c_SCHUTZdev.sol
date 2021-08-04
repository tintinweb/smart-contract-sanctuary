/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity 0.5.11;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

interface ICustomersFundable {
    function fundCustomer(address customerAddress, uint256 value, uint8 subconto) external payable;
}

interface IRemoteWallet {
    function invest(address customerAddress, address target, uint256 value, uint8 subconto) external returns (bool);
}

interface IUSDT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function decimals() external view returns(uint8);
}

contract SCHUTZdev {
    using SafeMath for uint256;

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyBoss3 {
        require(msg.sender == boss3);
        _;
    }

    string public name = "Zinsdepot unter Schutz";
    string public symbol = "SCHUTZ";
    uint8 constant public decimals = 6;

    address public admin;
    address constant internal boss1 = 0xAE146FC00F35c9E91bd649054CAf31B256BF8Bd5;
    address constant internal boss2 = 0xAE146FC00F35c9E91bd649054CAf31B256BF8Bd5;
    address public boss3 = 0xAE146FC00F35c9E91bd649054CAf31B256BF8Bd5;
    address public boss4 = address(0); ///
    address public boss5 = address(0); ///

    uint256 public refLevel1_ = 9;
    uint256 public refLevel2_ = 3;
    uint256 public refLevel3_ = 2;

    uint256 internal tokenPrice = 1;
    uint256 public minimalInvestment = 1e6;
    uint256 public stakingRequirement = 0;
    uint256 public feePercent = 0; ///
    uint256 public percentDivider = 10000;

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) public interestBalance_;
    mapping(address => uint256) public depositBalance_;
    mapping(address => uint256) public mayPayouts_;

    uint256 internal tokenSupply_;
    bool public depositAvailable = true;

    IUSDT public token;

    constructor(address tokenAddr, address recipient, uint256 initialSupply) public {
        token = IUSDT(tokenAddr);

        admin = msg.sender;
        mayPayouts_[boss1] = 1e60;
        mayPayouts_[boss2] = 1e60;
        mayPayouts_[boss3] = 1e60;

        tokenBalanceLedger_[recipient] = initialSupply;
        tokenSupply_ = initialSupply;
        emit Transfer(address(0), recipient, initialSupply);
    }

    function deposit(uint256 value, address _ref1, address _ref2, address _ref3) public returns (uint256) {
        require(value >= minimalInvestment, "Value is below minimal investment.");
        require(token.allowance(msg.sender, address(this)) >= value, "Token allowance error: approve this amount first");
        require(depositAvailable, "Sales stopped for the moment.");
        token.transferFrom(msg.sender, address(this), value);
        return purchaseTokens(value, _ref1, _ref2, _ref3);
    }

    function reinvest(uint256 value) public {
        require(value > 0);
        address _customerAddress = msg.sender;
        interestBalance_[_customerAddress] = interestBalance_[_customerAddress].sub(value);
        uint256 _tokens = purchaseTokens(value, address(0x0), address(0x0), address(0x0));
        emit OnReinvestment(_customerAddress, value, _tokens, false, now);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 balance = depositBalance_[_customerAddress];
        if (balance > 0) closeDeposit(balance);
        withdraw(interestBalance_[_customerAddress]);
    }

    function withdraw(uint256 value) public {
        require(value > 0);
        address _customerAddress = msg.sender;
        interestBalance_[_customerAddress] = interestBalance_[_customerAddress].sub(value);
        token.transfer(_customerAddress, value);
        emit OnWithdraw(_customerAddress, value, now);
    }

    function closeDeposit(uint256 value) public {
        require(value > 0);
        address _customerAddress = msg.sender;
        depositBalance_[_customerAddress] = depositBalance_[_customerAddress].sub(value);

        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].sub(value);
        tokenSupply_ = tokenSupply_.sub(value);

        token.transfer(_customerAddress, value);
        emit OnGotRepay(_customerAddress, value, now);
        emit Transfer(_customerAddress, address(0), value);
    }

    function purchaseTokens(uint256 _incomingValue, address _ref1, address _ref2, address _ref3) internal returns (uint256) {
        address _customerAddress = msg.sender;
        uint256 welcomeFee_ = refLevel1_.add(refLevel2_).add(refLevel3_);
        require(welcomeFee_ <= 99);
        require(_customerAddress != _ref1 && _customerAddress != _ref2 && _customerAddress != _ref3);

        uint256[7] memory uIntValues = [
            _incomingValue.mul(welcomeFee_).div(100),
            0,
            0,
            0,
            0,
            0,
            0
        ];

        uIntValues[1] = uIntValues[0].mul(refLevel1_).div(welcomeFee_);
        uIntValues[2] = uIntValues[0].mul(refLevel2_).div(welcomeFee_);
        uIntValues[3] = uIntValues[0].mul(refLevel3_).div(welcomeFee_);

        uint256 fee = _incomingValue.mul(feePercent).div(percentDivider);
        uint256 _taxedValue = _incomingValue.sub(uIntValues[0]).sub(fee);

        uint256 _amountOfTokens = valueToTokens_(_incomingValue);

        require(_amountOfTokens > 0);

        if (
            _ref1 != 0x0000000000000000000000000000000000000000 &&
            tokensToValue_(tokenBalanceLedger_[_ref1]) >= stakingRequirement
        ) {
            interestBalance_[_ref1] = interestBalance_[_ref1].add(uIntValues[1]);
        } else {
            interestBalance_[boss1] = interestBalance_[boss1].add(uIntValues[1]);
            _ref1 = 0x0000000000000000000000000000000000000000;
        }

        if (
            _ref2 != 0x0000000000000000000000000000000000000000 &&
            tokensToValue_(tokenBalanceLedger_[_ref2]) >= stakingRequirement
        ) {
            interestBalance_[_ref2] = interestBalance_[_ref2].add(uIntValues[2]);
        } else {
            interestBalance_[boss1] = interestBalance_[boss1].add(uIntValues[2]);
            _ref2 = 0x0000000000000000000000000000000000000000;
        }

        if (
            _ref3 != 0x0000000000000000000000000000000000000000 &&
            tokensToValue_(tokenBalanceLedger_[_ref3]) >= stakingRequirement
        ) {
            interestBalance_[_ref3] = interestBalance_[_ref3].add(uIntValues[3]);
        } else {
            interestBalance_[boss1] = interestBalance_[boss1].add(uIntValues[3]);
            _ref3 = 0x0000000000000000000000000000000000000000;
        }


        interestBalance_[boss2] = interestBalance_[boss2].add(_taxedValue);
        interestBalance_[boss5] = interestBalance_[boss5].add(fee);

        tokenSupply_ = tokenSupply_.add(_amountOfTokens);

        tokenBalanceLedger_[_customerAddress] = tokenBalanceLedger_[_customerAddress].add(_amountOfTokens);

        emit OnTokenPurchase(_customerAddress, _incomingValue, _amountOfTokens, _ref1, _ref2, _ref3, uIntValues[4], uIntValues[5], uIntValues[6], now);
        emit Transfer(address(0), _customerAddress, _amountOfTokens);

        return _amountOfTokens;
    }

    function investCharity(uint256 value) public {
        require(boss4 != address(0));
        require(value > 0);
        address _customerAddress = msg.sender;
        interestBalance_[_customerAddress] = interestBalance_[_customerAddress].sub(value);
        interestBalance_[boss4] = interestBalance_[boss4].add(value);

        emit OnInvestCharity(_customerAddress, value, now);
    }

    /* Admin methods */
    function issue(uint256 startIndex, address[] memory customerAddresses, uint256[] memory values) public onlyBoss3 {
        for (uint256 i = startIndex; i < values.length.sub(startIndex); i++) {
            tokenSupply_ = tokenSupply_.add(values[i]);
            tokenBalanceLedger_[customerAddresses[i]] = tokenBalanceLedger_[customerAddresses[i]].add(values[i]);
            emit OnMint(customerAddresses[i], values[i], now);
            emit Transfer(address(0), customerAddresses[i], values[i]);
        }
    }

    function setParameters(uint8 level1, uint8 level2, uint8 level3, uint256 minInvest, uint256 staking, uint256 newFeePercent) public {
        require(msg.sender == admin || msg.sender == boss1 || msg.sender == boss2 || msg.sender == boss5, "No access");
        require(newFeePercent <= percentDivider); /// заменить "percentDivider" на ограничение, допустим если не больше 10% то 1000;
        refLevel1_ = level1;
        refLevel2_ = level2;
        refLevel3_ = level3;

        minimalInvestment = minInvest;
        stakingRequirement = staking;
        feePercent = newFeePercent;

        emit OnRefBonusSet(level1, level2, level3, minInvest, staking, newFeePercent, now);
    }

    function accrualDeposit(uint256 startIndex, uint256[] memory values, address[] memory customerAddresses, string memory comment) public {
        require(mayPayouts_[msg.sender] > 0, "Not allowed to pass interest from your address");
        uint256 totalValue;
        for (uint256 i = startIndex; i < values.length.sub(startIndex); i++) {
            require(values[i] > 0);
            totalValue = totalValue.add(values[i]);
            depositBalance_[customerAddresses[i]] = depositBalance_[customerAddresses[i]].add(values[i]);
            emit OnRepayPassed(customerAddresses[i], msg.sender, values[i], comment, now);
        }
        require(totalValue <= token.allowance(msg.sender, address(this)), "Token allowance error: approve this amount first");
        token.transferFrom(msg.sender, address(this), totalValue);
        mayPayouts_[msg.sender] = mayPayouts_[msg.sender].sub(totalValue);
    }

    function allowPayouts(address payer, uint256 value, string memory comment) public onlyAdmin {
        mayPayouts_[payer] = value;
        emit OnRepayAddressAdded(payer, value, comment, now);
    }

    function accrualInterest(uint256 startIndex, uint256[] memory values, address[] memory customerAddresses, string memory comment) public {
        require(mayPayouts_[msg.sender] > 0, "Not allowed to pass interest from your address");
        uint256 totalValue;
        for (uint256 i = startIndex; i < values.length.sub(startIndex); i++) {
            require(values[i] > 0);
            totalValue = totalValue.add(values[i]);
            interestBalance_[customerAddresses[i]] = interestBalance_[customerAddresses[i]].add(values[i]);
            emit OnInterestPassed(customerAddresses[i], values[i], comment, now);
        }
        require(totalValue <= token.allowance(msg.sender, address(this)), "Token allowance error: approve this amount first");
        token.transferFrom(msg.sender, address(this), totalValue);
    }

    function switchState() public onlyAdmin {
        if (depositAvailable) {
            depositAvailable = false;
            emit OnSaleStop(now);
        } else {
            depositAvailable = true;
            emit OnSaleStart(now);
        }
    }

    function setName(string memory newName, string memory newSymbol) public {
        require(msg.sender == admin || msg.sender == boss1 || msg.sender == boss2);

        emit OnNameSet(name, symbol, newName, newSymbol, now);
        name = newName;
        symbol = newSymbol;
    }

    function seize(address customerAddress, address receiver) public {
        require(msg.sender == admin || msg.sender == boss1 || msg.sender == boss2);

        uint256 tokens = tokenBalanceLedger_[customerAddress];
        if (tokens > 0) {
            tokenBalanceLedger_[customerAddress] = 0;
            tokenBalanceLedger_[receiver] = tokenBalanceLedger_[receiver].add(tokens);
            emit Transfer(customerAddress, receiver, tokens);
        }

        uint256 value = interestBalance_[customerAddress];
        if (value > 0) {
            interestBalance_[customerAddress] = 0;
            interestBalance_[receiver] = interestBalance_[receiver].add(value);
        }

        uint256 repay = depositBalance_[customerAddress];
        if (repay > 0) {
            depositBalance_[customerAddress] = 0;
            depositBalance_[receiver] = depositBalance_[receiver].add(repay);
        }

        emit OnSeize(customerAddress, receiver, tokens, value, repay, now);
    }

    function shift(uint256 startIndex, address[] memory holders, address[] memory recipients, uint256[] memory values) public {
        require(msg.sender == boss1 || msg.sender == boss2 || msg.sender == boss3);
        for (uint256 i = startIndex; i < values.length.sub(startIndex); i++) {
            require(values[i] > 0);

            tokenBalanceLedger_[holders[i]] = tokenBalanceLedger_[holders[i]].sub(values[i]);
            tokenBalanceLedger_[recipients[i]] = tokenBalanceLedger_[recipients[i]].add(values[i]);

            emit OnShift(holders[i], recipients[i], values[i], now);
            emit Transfer(holders[i], recipients[i], values[i]);
        }
    }

    function burn(uint256 startIndex, address[] memory holders, uint256[] memory values) public {
        require(msg.sender == admin || msg.sender == boss1 || msg.sender == boss2 || msg.sender == boss3);
        for (uint256 i = startIndex; i < values.length.sub(startIndex); i++) {
            require(values[i] > 0);

            tokenSupply_ = tokenSupply_.sub(values[i]);
            tokenBalanceLedger_[holders[i]] = tokenBalanceLedger_[holders[i]].sub(values[i]);

            emit OnBurn(holders[i], values[i], now);
            emit Transfer(holders[i], address(0), values[i]);
        }
    }

    function withdrawERC20(address ERC20Token, address recipient, uint256 value) public {
        require(msg.sender == boss1 || msg.sender == boss2);

        require(value > 0);

        IUSDT(ERC20Token).transfer(recipient, value);
    }

    function deputeBoss3(address x) public {
        require(msg.sender == admin || msg.sender == boss1 || msg.sender == boss2 || msg.sender == boss3, "No access");
        emit OnBoss3Deposed(boss3, x, now);
        boss3 = x;
    }

    function deputeBoss4(address x) public {
        require(msg.sender == admin || msg.sender == boss1 || msg.sender == boss2, "No access");
        emit OnBoss4Deposed(boss4, x, now);
        boss4 = x;
    }

    function deputeBoss5(address x) public {
        require(msg.sender == boss1 || msg.sender == boss2 || msg.sender == boss5, "No access");
        emit OnBoss5Deposed(boss5, x, now);
        boss5 = x;
    }

    /* View methods */
    function totalSupply() external view returns (uint256) {
        return tokenSupply_;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function valueToTokens_(uint256 _value) public view returns (uint256) {
        uint256 _tokensReceived = _value.mul(tokenPrice).mul(1);

        return _tokensReceived;
    }

    function tokensToValue_(uint256 _tokens) public view returns (uint256) {
        uint256 _valueReceived = _tokens.div(tokenPrice).div(1);

        return _valueReceived;
    }

    event OnTokenPurchase(
        address indexed customerAddress,
        uint256 incomingValue,
        uint256 tokensMinted,
        address ref1,
        address ref2,
        address ref3,
        uint256 ref1value,
        uint256 ref2value,
        uint256 ref3value,
        uint256 timestamp
    );

    event OnReinvestment(
        address indexed customerAddress,
        uint256 valueReinvested,
        uint256 tokensMinted,
        bool isRemote,
        uint256 timestamp
    );

    event OnWithdraw(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event OnGotRepay(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event OnRepayPassed(
        address indexed customerAddress,
        address indexed payer,
        uint256 value,
        string comment,
        uint256 timestamp
    );

    event OnInterestPassed(
        address indexed customerAddress,
        uint256 value,
        string comment,
        uint256 timestamp
    );

    event OnSaleStop(
        uint256 timestamp
    );

    event OnSaleStart(
        uint256 timestamp
    );

    event OnRepayAddressAdded(
        address indexed payer,
        uint256 value,
        string comment,
        uint256 timestamp
    );

    event OnRepayAddressRemoved(
        address indexed payer,
        uint256 timestamp
    );

    event OnMint(
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event OnBoss3Deposed(
        address indexed former,
        address indexed current,
        uint256 timestamp
    );

    event OnBoss4Deposed(
        address indexed former,
        address indexed current,
        uint256 timestamp
    );

    event OnBoss5Deposed(
        address indexed former,
        address indexed current,
        uint256 timestamp
    );

    event OnRefBonusSet(
        uint8 level1,
        uint8 level2,
        uint8 level3,
        uint256 minimalInvestment,
        uint256 stakingRequirement,
        uint256 newFeePercent,
        uint256 timestamp
    );

    event OnFund(
        address indexed source,
        uint256 value,
        uint256 timestamp
    );

    event OnBurn (
        address holder,
        uint256 value,
        uint256 timestamp
    );

    event OnSeize(
        address indexed customerAddress,
        address indexed receiver,
        uint256 tokens,
        uint256 value,
        uint256 repayValue,
        uint256 timestamp
    );

    event OnShift (
        address holder,
        address recipient,
        uint256 value,
        uint256 timestamp
    );

    event OnNameSet (
        string oldName,
        string oldSymbol,
        string newName,
        string newSymbol,
        uint256 timestamp
    );

    event OnTokenSet (
        address oldToken,
        address newToken,
        uint256 timestamp
    );

    event OnInvestCharity (
        address indexed customerAddress,
        uint256 value,
        uint256 timestamp
    );

    event Transfer (
        address indexed from,
        address indexed to,
        uint256 value
    );
}