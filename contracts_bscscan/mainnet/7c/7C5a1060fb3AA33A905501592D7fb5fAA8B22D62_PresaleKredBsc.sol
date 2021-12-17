/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

pragma solidity ^0.8.9;
// SPDX-License-Identifier: MIT

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address newOwner) {
        _setOwner(newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "$KRED: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "$KRED: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BEP20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "$KRED: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "$KRED: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "$KRED: transfer from the zero address");
        require(recipient != address(0), "$KRED: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "$KRED: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "$KRED: mint to the zero address");
        require(_totalSupply + amount <= 10 * (10**12) * (10**18), "Total Supply exceeded");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "$KRED: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "$KRED: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "$KRED: approve from the zero address");
        require(spender != address(0), "$KRED: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


}

contract KredToken is BEP20, Ownable {

    address minter;
    uint public lastMintTime = 0;

    constructor() Ownable(msg.sender) BEP20("KRED", "$KRED", 18) {

    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function mintForSmartContract(uint _amt) public {
        require (msg.sender == minter, "Only minter can mint");
        _mint(msg.sender, _amt);   
    }

    function mintForOwner(uint _amt) public onlyOwner {
        require(block.timestamp - lastMintTime > 12 hours, "Mint rate too fast");
        require(_amt <= 10 * (10**10) * (10**18), "Max Mint amount for owner exceeded");
        _mint(msg.sender, _amt);   
        lastMintTime = block.timestamp;
    }

}

interface IBEP20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

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

contract VerifySignature {
    address internal signer;

    function verify(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _user,
            uint2str(_slotsQty[0]),
            uint2str(_slotsQty[1]),
            uint2str(_slotsQty[2]),
            uint2str(_nonce)
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _sign) == signer;
    }

    function getMessageHash(
        address _user,
        string memory _slotsQty1,
        string memory _slotsQty2,
        string memory _slotsQty3,
        string memory _nonce
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _user,
                    _slotsQty1,
                    _slotsQty2,
                    _slotsQty3,
                    _nonce
                )
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function uint2str(uint256 _i)
        private
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

contract PresaleKredBsc is VerifySignature {

    address payable public owner;
    // Token address
    KredToken public kredToken;
    IBEP20 public jedToken = IBEP20(0x058a7Af19BdB63411d0a84e79E3312610D7fa90c);
    address[3] public coins = [
        0x55d398326f99059fF775485246999027B3197955, // USDT
        0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3, // DAI
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 // BUSD
    ];
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

    // Contract States
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public claimStartTime;
    bool public isClaimEnabled;

    uint256 public percentDivider = 100;
    uint256 public timeStep = 30 days;
    uint256[5] public tokensPerSlot = [
        100000000e18,
        33333333e18,
        10000000e18,
        500000000e18,
        400000000e18
    ];
    // Whitelist Presale
    uint256[6] public whitelistClaimAmountU1 = [10, 10, 20, 20, 20, 20];
    uint256[6] public whitelistClaimAmountU2 = [25, 15, 15, 15, 15, 15];
    // Public Presale
    uint256[5] public usdSlots = [4000, 2000, 800, 10000, 8000];
    uint256[5] public totalClaims = [4, 2, 1, 6, 6];

    struct Slot {
        uint256 tokenBalance;
        uint256 totalClaimedTokens;
        uint256 remainingClaims;
        uint256[4] claimDate;
        uint256[] claimPercentage;
    }

    mapping(address => mapping(uint256 => Slot)) public users;
    mapping(address => uint256) public nextUnlockDate;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public nonce;

    modifier onlyOwner() {
        require(msg.sender == owner, "PreSale: Not an owner");
        _;
    }

    modifier isWhitelisted(address _user) {
        require(whitelist[_user], "PreSale: Not a vip user");
        _;
    }

    modifier isVerified(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) {
        require(_nonce > nonce[msg.sender], "Presale: invalid nonce");
        require(
            verify(_user, _slotsQty, _nonce, _sign),
            "Presale: Unverified."
        );
        _;
    }

    event BuyToken(address _user, uint256 _amount);
    event ClaimToken(address _user, uint256 _amount);

    constructor(
        address _signer,
        KredToken _kredToken
    ) {
        owner = payable(msg.sender);
        signer = _signer;
        kredToken = _kredToken;

        // Setting presale time.
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + 10 days;
    }

    receive() external payable {}

    // to buy token during public preSale time => for web3 use
    function buyTokenBNB(
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public payable isVerified(msg.sender, _slotsQty, _nonce, _sign) {
        require(_slotsQty.length == 3, "PreSale: Invalid Slots");
        require(
            jedToken.balanceOf(msg.sender) >= 1000e18,
            "PreSale: Insufficient JED Tokens."
        );
        require(
            block.timestamp >= preSaleStartTime,
            "PreSale: PreSale not started yet"
        );
        require(block.timestamp < preSaleEndTime, "PreSale: PreSale over");
        // Check requried bnb for slot.
        uint256 totalUsd = usdSlots[0] * (_slotsQty[0]);
        totalUsd = totalUsd + (usdSlots[1] * (_slotsQty[1]));
        totalUsd = totalUsd + (usdSlots[2] * (_slotsQty[2]));
        require(msg.value >= usdToBNB(totalUsd), "PreSale: Invalid Amount");
        amountRaised = amountRaised + (totalUsd);

        uint256 totalTokens;
        for (uint256 i = 0; i < 3; i++) {
            if (_slotsQty[i] > 0) {
                _updateUserData(msg.sender, i, _slotsQty[i]);
                totalTokens = totalTokens + (tokensPerSlot[i] * (_slotsQty[i]));
            }
        }

        require(totalTokens > 0, "Presale: not buy any slot.");
        kredToken.mintForSmartContract(totalTokens);
        nonce[msg.sender] = _nonce;
        emit BuyToken(msg.sender, totalTokens);
    }

    // to buy token during public preSale time => for web3 use
    function buyToken(
        uint256 choice,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public isVerified(msg.sender, _slotsQty, _nonce, _sign) {
        require(_slotsQty.length == 3, "PreSale: Invalid Slots");
        require(choice < coins.length, "PreSale: Invalid token");
        require(
            jedToken.balanceOf(msg.sender) >= 1000e18,
            "Insufficient JED Tokens."
        );
        require(
            block.timestamp >= preSaleStartTime,
            "PreSale: PreSale not started yet"
        );
        require(block.timestamp < preSaleEndTime, "PreSale: PreSale over");

        uint256 totalUsd = usdSlots[0] * (_slotsQty[0]);
        totalUsd = totalUsd + (usdSlots[1] * (_slotsQty[1]));
        totalUsd = totalUsd + (usdSlots[2] * (_slotsQty[2]));
        uint256 totalDecimals = 10**IBEP20(coins[choice]).decimals();
        IBEP20(coins[choice]).transferFrom(
            msg.sender,
            owner,
            totalUsd * (totalDecimals)
        );
        amountRaised = amountRaised + totalUsd;

        uint256 totalTokens;
        for (uint256 i = 0; i < 3; i++) {
            if (_slotsQty[i] > 0) {
                _updateUserData(msg.sender, i, _slotsQty[i]);

                // Event trigger.
                totalTokens = totalTokens + (
                    tokensPerSlot[i] * (_slotsQty[i])
                );
            }
        }

        require(totalTokens > 0, "Presale: not buy any slot.");
        kredToken.mintForSmartContract(totalTokens);
        nonce[msg.sender] = _nonce;
        emit BuyToken(msg.sender, totalTokens);
    }

    function _updateUserData(
        address _user,
        uint256 slotIndex,
        uint256 _qty
    ) private {
        // Set User data.
        users[_user][slotIndex].tokenBalance = users[_user][slotIndex].tokenBalance
             + (tokensPerSlot[slotIndex] * _qty);
        users[_user][slotIndex].remainingClaims = totalClaims[slotIndex];

        // Set total info
        soldToken = soldToken + (tokensPerSlot[slotIndex] * _qty);
    }

    // to claim tokens in vesting => for web3 use
    function claim() public {
        // Claim checks.
        require(isClaimEnabled, "Presale: Claim not started yet");
        require(
            getUserTotalTokens(msg.sender) > 0,
            "Presale: Insufficient Balance"
        );
        // Check if claim date is available
        if (nextUnlockDate[msg.sender] == 0) {
            require(
                block.timestamp > claimStartTime + timeStep,
                "Presale: Wait for first claim."
            );
            nextUnlockDate[msg.sender] = claimStartTime + (timeStep * (2));
        } else {
            require(
                block.timestamp > nextUnlockDate[msg.sender],
                "Presale: Wait for next claim."
            );
            nextUnlockDate[msg.sender] = nextUnlockDate[msg.sender] + (
                timeStep
            );
        }

        uint256 totalClaimeable;
        for (uint256 slotIndex = 0; slotIndex < usdSlots.length; slotIndex++) {
            if (users[msg.sender][slotIndex].tokenBalance > 0) {
                totalClaimeable = totalClaimeable + _claim(msg.sender, slotIndex);
            }
        }

        require(totalClaimeable > 0, "No claimable balance.");
        kredToken.transfer(msg.sender, totalClaimeable);
        emit ClaimToken(msg.sender, totalClaimeable);
    }

    function _claim(address _user, uint256 slotIndex) internal returns (uint256) {
        // Claim checks.
        Slot storage user = users[_user][slotIndex];
        if (user.remainingClaims == 0) {
            return 0;
        }

        // Claim processing.
        // Get Dividend by user type
        uint256 dividends;
        if (slotIndex > 2) {
            uint256 claimIndex = user.claimPercentage.length -
                user.remainingClaims;
            dividends = user.tokenBalance * user.claimPercentage[claimIndex] / percentDivider;
        } else {
            dividends = user.tokenBalance / totalClaims[slotIndex];
        }

        // Setting next claim date.
        user.totalClaimedTokens = user.totalClaimedTokens + dividends;
        user.remainingClaims = user.remainingClaims - (1);

        return dividends;
    }

    // set presale for whitelist users.
    function setEthUsers (
        address[] memory _users,
        uint256[] memory _firstSlots,
        uint256[] memory _secondSlots,
        uint256[] memory _thirdSlots
    ) public onlyOwner{
        require(
            _users.length == _firstSlots.length,
            "Users and first slots are not equal"
        );
        require(
            _users.length == _secondSlots.length,
            "Users and second slots are not equal"
        );
        require(
            _users.length == _thirdSlots.length,
            "Users and third slots are not equal"
        );

        uint256 totalTokens;
        for (uint256 i = 0; i < _users.length; i++) {
            totalTokens = totalTokens + (
                _firstSlots[i] + (_secondSlots[i]) + (_thirdSlots[i])
            );
            // Setting first slot user data.
            if (_firstSlots[i] > 0) {
                users[_users[i]][0].tokenBalance = users[_users[i]][0]
                    .tokenBalance
                     + (_firstSlots[i]);
                users[_users[i]][0].remainingClaims = totalClaims[0];
            }
            // Setting second slot user data.
            if (_secondSlots[i] > 0) {
                users[_users[i]][1].tokenBalance = users[_users[i]][1]
                    .tokenBalance
                    + (_secondSlots[i]);
                users[_users[i]][1].remainingClaims = totalClaims[1];
            }
            // Setting third slot user data.
            if (_thirdSlots[i] > 0) {
                users[_users[i]][2].tokenBalance = users[_users[i]][2]
                    .tokenBalance
                    + (_thirdSlots[i]);
                users[_users[i]][2].remainingClaims = totalClaims[2];
            }
        }
        kredToken.mintForSmartContract(totalTokens);
        soldToken = soldToken + (totalTokens);
    }

    // set presale for whitelist users.
    function setVipUsers(
        address[] memory _users,
        uint256[] memory _firstSlots,
        uint256[] memory _secondSlots
    ) public onlyOwner{
        require(
            _users.length == _firstSlots.length,
            "Users and first slots are not equal"
        );
        require(
            _users.length == _secondSlots.length,
            "Users and second slots are not equal"
        );

        uint256 totalTokens;
        for (uint256 i = 0; i < _users.length; i++) {
            totalTokens = totalTokens + (_firstSlots[i] + (_secondSlots[i]));
            // Setting first vip slot user data.
            if (_firstSlots[i] > 0) {
                users[_users[i]][3].tokenBalance = users[_users[i]][3]
                    .tokenBalance
                    + (_firstSlots[i]);
                users[_users[i]][3].remainingClaims = totalClaims[3];
                users[_users[i]][3].claimPercentage = whitelistClaimAmountU1;
            }
            // Setting second vip slot user data.
            if (_secondSlots[i] > 0) {
                users[_users[i]][4].tokenBalance = users[_users[i]][4]
                    .tokenBalance
                    + (_secondSlots[i]);
                users[_users[i]][4].remainingClaims = totalClaims[4];
                users[_users[i]][4].claimPercentage = whitelistClaimAmountU2;
            }

            // settting total.
            whitelist[_users[i]] = true;
        }
        kredToken.mintForSmartContract(totalTokens);
        soldToken = soldToken + (totalTokens);
    }

    function getUserTotalTokens(address _user)
        public
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < usdSlots.length; i++) {
            total = total + (users[_user][i].tokenBalance);
        }
    }

    function usdToBNB(uint256 value) public view returns (uint256) {
        return value * (1e18) * (10**priceFeed.decimals()) / (getLatestPriceBNB());
    }


    function getLatestPriceBNB() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getUserSlotInfo(address _user, uint256 slotIndex)
        public
        view
        returns (
            uint256 purchases,
            uint256 claimed_tokens,
            uint256 next_claim_date,
            uint256 next_claim_amount
        )
    {
        require(slotIndex < 5, "Presale: Invalid Slot");

        Slot storage user = users[_user][slotIndex];
        // Get Dividend by user type
        uint256 dividends;
        uint256 _nextUnlockDate;
        if (user.remainingClaims > 0) {
            if (slotIndex > 2) {
                uint256 claimIndex = user.claimPercentage.length -
                    user.remainingClaims;
                dividends = user.tokenBalance * user.claimPercentage[claimIndex] / percentDivider;
            } else {
                dividends = user.tokenBalance / totalClaims[slotIndex];
            }
            _nextUnlockDate = nextUnlockDate[_user];
            if (claimStartTime != 0 && nextUnlockDate[_user] == 0) {
                _nextUnlockDate = claimStartTime + timeStep;
            }
        }

        return (
            user.tokenBalance,
            user.totalClaimedTokens,
            _nextUnlockDate,
            dividends
        );
    }

    function startClaim() public onlyOwner {
        require(
            block.timestamp > preSaleEndTime && !isClaimEnabled,
            "Presale: Not over yet."
        );
        isClaimEnabled = true;
        claimStartTime = block.timestamp;
    }

    function updatePriceAggregator(address _feedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function setPublicPreSale(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function changeJedToken(address _token) external onlyOwner {
        jedToken = IBEP20(_token);
    }

    function updateCoinAddress(uint256 choice, address _token)
        external
        onlyOwner
    {
        require(choice < coins.length, "Invalid token");
        coins[choice] = _token;
    }

    function withdrawBNB(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    function withdrawToken(address _token, uint256 _value) external onlyOwner {
        require(KredToken(_token) != kredToken, "Invalid token");
        IBEP20(_token).transfer(owner, _value);
    }
}