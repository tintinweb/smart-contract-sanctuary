pragma solidity ^0.4.15;

/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic authorization control functions, this simplifies
/// and the implementation of "user permissions".
contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender
    /// account.
    function Ownable() {
        owner = msg.sender;
    }

    /// @dev Reverts if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }

        _;
    }

    modifier onlyOwnerCandidate() {
        if (msg.sender != newOwnerCandidate) {
            revert();
        }

        _;
    }

    /// @dev Proposes to transfer control of the contract to a newOwnerCandidate.
    /// @param _newOwnerCandidate address The address to transfer ownership to.
    function requestOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// @dev Accept ownership transfer. This method needs to be called by the previously proposed owner.
    function acceptOwnership() external onlyOwnerCandidate {
        address previousOwner = owner;

        owner = newOwnerCandidate;
        newOwnerCandidate = address(0);

        OwnershipTransferred(previousOwner, owner);
    }
}

/// @title Math operations with safety checks
library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

/// @title ERC Token Standard #20 Interface (https://github.com/ethereum/EIPs/issues/20)
contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/// @title Basic ERC20 token contract implementation.
/// @dev Based on OpenZeppelin&#39;s StandardToken.
contract BasicToken is ERC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) balances;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    /// @param _spender address The address which will spend the funds.
    /// @param _value uint256 The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) public returns (bool) {
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    /// @dev Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner address The address which owns the funds.
    /// @param _spender address The address which will spend the funds.
    /// @return uint256 specifying the amount of tokens still available for the spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    /// @dev Gets the balance of the specified address.
    /// @param _owner address The address to query the the balance of.
    /// @return uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev transfer token to a specified address.
    /// @param _to address The address to transfer to.
    /// @param _value uint256 The amount to be transferred.
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

    /// @dev Transfer tokens from one address to another.
    /// @param _from address The address which you want to send tokens from.
    /// @param _to address The address which you want to transfer to.
    /// @param _value uint256 the amount of tokens to be transferred.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }
}


/// @title Token holder contract.
contract TokenHolder is Ownable {
    /// @dev Allow the owner to transfer out any accidentally sent ERC20 tokens.
    /// @param _tokenAddress address The address of the ERC20 contract.
    /// @param _amount uint256 The amount of tokens to be transferred.
    function transferAnyERC20Token(address _tokenAddress, uint256 _amount) onlyOwner returns (bool success) {
        return ERC20(_tokenAddress).transfer(owner, _amount);
    }
}


/// @title Kin token contract.
contract KinToken is Ownable, BasicToken, TokenHolder {
    using SafeMath for uint256;

    string public constant name = "Kin";
    string public constant symbol = "KIN";

    // Using same decimal value as ETH (makes ETH-KIN conversion much easier).
    uint8 public constant decimals = 18;

    // States whether creating more tokens is allowed or not.
    // Used during token sale.
    bool public isMinting = true;

    event MintingEnded();

    modifier onlyDuringMinting() {
        require(isMinting);

        _;
    }

    modifier onlyAfterMinting() {
        require(!isMinting);

        _;
    }

    /// @dev Mint Kin tokens.
    /// @param _to address Address to send minted Kin to.
    /// @param _amount uint256 Amount of Kin tokens to mint.
    function mint(address _to, uint256 _amount) external onlyOwner onlyDuringMinting {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Transfer(0x0, _to, _amount);
    }

    /// @dev End minting mode.
    function endMinting() external onlyOwner {
        if (isMinting == false) {
            return;
        }

        isMinting = false;

        MintingEnded();
    }

    /// @dev Same ERC20 behavior, but reverts if still minting.
    /// @param _spender address The address which will spend the funds.
    /// @param _value uint256 The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) public onlyAfterMinting returns (bool) {
        return super.approve(_spender, _value);
    }

    /// @dev Same ERC20 behavior, but reverts if still minting.
    /// @param _to address The address to transfer to.
    /// @param _value uint256 The amount to be transferred.
    function transfer(address _to, uint256 _value) public onlyAfterMinting returns (bool) {
        return super.transfer(_to, _value);
    }

    /// @dev Same ERC20 behavior, but reverts if still minting.
    /// @param _from address The address which you want to send tokens from.
    /// @param _to address The address which you want to transfer to.
    /// @param _value uint256 the amount of tokens to be transferred.
    function transferFrom(address _from, address _to, uint256 _value) public onlyAfterMinting returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}


/// @title Vesting trustee contract for Kin token.
contract VestingTrustee is Ownable {
    using SafeMath for uint256;

    // Kin token contract.
    KinToken public kin;

    // Vesting grant for a speicifc holder.
    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 installmentLength; // In seconds.
        uint256 transferred;
        bool revokable;
    }

    // Holder to grant information mapping.
    mapping (address => Grant) public grants;

    // Total tokens available for vesting.
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event TokensUnlocked(address indexed _to, uint256 _value);
    event GrantRevoked(address indexed _holder, uint256 _refund);

    /// @dev Constructor that initializes the address of the Kin token contract.
    /// @param _kin KinToken The address of the previously deployed Kin token contract.
    function VestingTrustee(KinToken _kin) {
        require(_kin != address(0));

        kin = _kin;
    }

    /// @dev Grant tokens to a specified address. Please note, that the trustee must have enough ungranted tokens to
    /// accomodate the new grant. Otherwise, the call with fail.
    /// @param _to address The holder address.
    /// @param _value uint256 The amount of tokens to be granted.
    /// @param _start uint256 The beginning of the vesting period.
    /// @param _cliff uint256 Duration of the cliff period (when the first installment is made).
    /// @param _end uint256 The end of the vesting period.
    /// @param _installmentLength uint256 The length of each vesting installment (in seconds).
    /// @param _revokable bool Whether the grant is revokable or not.
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end,
        uint256 _installmentLength, bool _revokable)
        external onlyOwner {

        require(_to != address(0));
        require(_to != address(this)); // Protect this contract from receiving a grant.
        require(_value > 0);

        // Require that every holder can be granted tokens only once.
        require(grants[_to].value == 0);

        // Require for time ranges to be consistent and valid.
        require(_start <= _cliff && _cliff <= _end);

        // Require installment length to be valid and no longer than (end - start).
        require(_installmentLength > 0 && _installmentLength <= _end.sub(_start));

        // Grant must not exceed the total amount of tokens currently available for vesting.
        require(totalVesting.add(_value) <= kin.balanceOf(address(this)));

        // Assign a new grant.
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            installmentLength: _installmentLength,
            transferred: 0,
            revokable: _revokable
        });

        // Since tokens have been granted, reduce the total amount available for vesting.
        totalVesting = totalVesting.add(_value);

        NewGrant(msg.sender, _to, _value);
    }

    /// @dev Revoke the grant of tokens of a specifed address.
    /// @param _holder The address which will have its tokens revoked.
    function revoke(address _holder) public onlyOwner {
        Grant memory grant = grants[_holder];

        // Grant must be revokable.
        require(grant.revokable);

        // Calculate amount of remaining tokens that can still be returned.
        uint256 refund = grant.value.sub(grant.transferred);

        // Remove the grant.
        delete grants[_holder];

        // Update total vesting amount and transfer previously calculated tokens to owner.
        totalVesting = totalVesting.sub(refund);
        kin.transfer(msg.sender, refund);

        GrantRevoked(_holder, refund);
    }

    /// @dev Calculate the total amount of vested tokens of a holder at a given time.
    /// @param _holder address The address of the holder.
    /// @param _time uint256 The specific time to calculate against.
    /// @return a uint256 Representing a holder&#39;s total amount of vested tokens.
    function vestedTokens(address _holder, uint256 _time) external constant returns (uint256) {
        Grant memory grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

    /// @dev Calculate amount of vested tokens at a specifc time.
    /// @param _grant Grant The vesting grant.
    /// @param _time uint256 The time to be checked
    /// @return An uint256 Representing the amount of vested tokens of a specific grant.
    function calculateVestedTokens(Grant _grant, uint256 _time) private constant returns (uint256) {
        // If we&#39;re before the cliff, then nothing is vested.
        if (_time < _grant.cliff) {
            return 0;
        }

        // If we&#39;re after the end of the vesting period - everything is vested;
        if (_time >= _grant.end) {
            return _grant.value;
        }

        // Calculate amount of installments past until now.
        //
        // NOTE result gets floored because of integer division.
        uint256 installmentsPast = _time.sub(_grant.start).div(_grant.installmentLength);

        // Calculate amount of days in entire vesting period.
        uint256 vestingDays = _grant.end.sub(_grant.start);

        // Calculate and return the number of tokens according to vesting days that have passed.
        return _grant.value.mul(installmentsPast.mul(_grant.installmentLength)).div(vestingDays);
    }

    /// @dev Unlock vested tokens and transfer them to the grantee.
    function unlockVestedTokens() external {
        Grant storage grant = grants[msg.sender];

        // Make sure the grant has tokens available.
        require(grant.value != 0);

        // Get the total amount of vested tokens, acccording to grant.
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            return;
        }

        // Make sure the holder doesn&#39;t transfer more than what he already has.
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            return;
        }

        // Update transferred and total vesting amount, then transfer remaining vested funds to holder.
        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        kin.transfer(msg.sender, transferable);

        TokensUnlocked(msg.sender, transferable);
    }
}


/// @title Kin token sale contract.
contract KinTokenSale is Ownable, TokenHolder {
    using SafeMath for uint256;

    // External parties:

    // KIN token contract.
    KinToken public kin;

    // Vesting contract for pre-sale participants.
    VestingTrustee public trustee;

    // Received funds are forwarded to this address.
    address public fundingRecipient;

    // Kin token unit.
    // Using same decimal value as ETH (makes ETH-KIN conversion much easier).
    // This is the same as in Kin token contract.
    uint256 public constant TOKEN_UNIT = 10 ** 18;

    // Maximum number of tokens in circulation: 10 trillion.
    uint256 public constant MAX_TOKENS = 10 ** 13 * TOKEN_UNIT;

    // Maximum tokens offered in the sale.
    uint256 public constant MAX_TOKENS_SOLD = 512195121951 * TOKEN_UNIT;

    // Wei to 1 USD ratio.
    uint256 public constant WEI_PER_USD = uint256(1 ether) / 289;

    // KIN to 1 USD ratio,
    // such that MAX_TOKENS_SOLD / KIN_PER_USD is the $75M cap.
    uint256 public constant KIN_PER_USD = 6829 * TOKEN_UNIT;

    // KIN to 1 wei ratio.
    uint256 public constant KIN_PER_WEI = KIN_PER_USD / WEI_PER_USD;

    // Sale start and end timestamps.
    uint256 public constant SALE_DURATION = 14 days;
    uint256 public startTime;
    uint256 public endTime;

    // Amount of tokens sold until now in the sale.
    uint256 public tokensSold = 0;

    // Participation caps, according to KYC tiers.
    uint256 public constant TIER_1_CAP = 100000 * WEI_PER_USD;
    uint256 public constant TIER_2_CAP = uint256(-1); // Maximum uint256 value

    // Accumulated amount each participant has contributed so far.
    mapping (address => uint256) public participationHistory;

    // Maximum amount that each participant is allowed to contribute (in WEI).
    mapping (address => uint256) public participationCaps;

    // Maximum amount ANYBODY is currently allowed to contribute.
    uint256 public hardParticipationCap = 4393 * WEI_PER_USD;

    // Vesting information for special addresses:
    struct TokenGrant {
        uint256 value;
        uint256 startOffset;
        uint256 cliffOffset;
        uint256 endOffset;
        uint256 installmentLength;
        uint8 percentVested;
    }

    address[] public tokenGrantees;
    mapping (address => TokenGrant) public tokenGrants;
    uint256 public lastGrantedIndex = 0;
    uint256 public constant MAX_TOKEN_GRANTEES = 100;
    uint256 public constant GRANT_BATCH_SIZE = 10;

    // Post-TDE multisig addresses.
    address public constant KIN_FOUNDATION_ADDRESS = 0x56aE76573EC54754bC5B6A8cBF04bBd7Dc86b0A0;
    address public constant KIK_ADDRESS = 0x3bf4BbE253153678E9E8E540395C22BFf7fCa87d;

    event TokensIssued(address indexed _to, uint256 _tokens);

    /// @dev Reverts if called when not during sale.
    modifier onlyDuringSale() {
        require(!saleEnded() && now >= startTime);

        _;
    }

    /// @dev Reverts if called before sale ends.
    modifier onlyAfterSale() {
        require(saleEnded());

        _;
    }

    /// @dev Constructor that initializes the sale conditions.
    /// @param _fundingRecipient address The address of the funding recipient.
    /// @param _startTime uint256 The start time of the token sale.
    function KinTokenSale(address _fundingRecipient, uint256 _startTime) {
        require(_fundingRecipient != address(0));
        require(_startTime > now);

        // Deploy new KinToken contract.
        kin = new KinToken();

        // Deploy new VestingTrustee contract.
        trustee = new VestingTrustee(kin);

        fundingRecipient = _fundingRecipient;
        startTime = _startTime;
        endTime = startTime + SALE_DURATION;

        // Initialize special vesting grants.
        initTokenGrants();
    }

    /// @dev Initialize token grants.
    function initTokenGrants() private onlyOwner {
        // Issue the remaining 60% to Kin Foundation&#39;s multisig wallet. In a few days, after the token sale is
        // finalized, these tokens will be loaded into the KinVestingTrustee smart contract, according to the white
        // paper. Please note, that this is implied by setting a 0% vesting percent.
        tokenGrantees.push(KIN_FOUNDATION_ADDRESS);
        tokenGrants[KIN_FOUNDATION_ADDRESS] = TokenGrant(MAX_TOKENS.mul(60).div(100), 0, 0, 3 years, 1 days, 0);

        // Kik, 30%
        tokenGrantees.push(KIK_ADDRESS);
        tokenGrants[KIK_ADDRESS] = TokenGrant(MAX_TOKENS.mul(30).div(100), 0, 0, 120 weeks, 12 weeks, 100);
    }

    /// @dev Adds a Kin token vesting grant.
    /// @param _grantee address The address of the token grantee. Can be granted only once.
    /// @param _value uint256 The value of the grant.
    function addTokenGrant(address _grantee, uint256 _value) external onlyOwner {
        require(_grantee != address(0));
        require(_value > 0);
        require(tokenGrantees.length + 1 <= MAX_TOKEN_GRANTEES);

        // Verify the grant doesn&#39;t already exist.
        require(tokenGrants[_grantee].value == 0);
        for (uint i = 0; i < tokenGrantees.length; i++) {
            require(tokenGrantees[i] != _grantee);
        }

        // Add grant and add to grantee list.
        tokenGrantees.push(_grantee);
        tokenGrants[_grantee] = TokenGrant(_value, 0, 1 years, 1 years, 1 days, 50);
    }

    /// @dev Deletes a Kin token grant.
    /// @param _grantee address The address of the token grantee.
    function deleteTokenGrant(address _grantee) external onlyOwner {
        require(_grantee != address(0));

        // Delete the grant from the keys array.
        for (uint i = 0; i < tokenGrantees.length; i++) {
            if (tokenGrantees[i] == _grantee) {
                delete tokenGrantees[i];

                break;
            }
        }

        // Delete the grant from the mapping.
        delete tokenGrants[_grantee];
    }

    /// @dev Add a list of participants to a capped participation tier.
    /// @param _participants address[] The list of participant addresses.
    /// @param _cap uint256 The cap amount (in ETH).
    function setParticipationCap(address[] _participants, uint256 _cap) private onlyOwner {
        for (uint i = 0; i < _participants.length; i++) {
            participationCaps[_participants[i]] = _cap;
        }
    }

    /// @dev Add a list of participants to cap tier #1.
    /// @param _participants address[] The list of participant addresses.
    function setTier1Participants(address[] _participants) external onlyOwner {
        setParticipationCap(_participants, TIER_1_CAP);
    }

    /// @dev Add a list of participants to tier #2.
    /// @param _participants address[] The list of participant addresses.
    function setTier2Participants(address[] _participants) external onlyOwner {
        setParticipationCap(_participants, TIER_2_CAP);
    }

    /// @dev Set hard participation cap for all participants.
    /// @param _cap uint256 The hard cap amount.
    function setHardParticipationCap(uint256 _cap) external onlyOwner {
        require(_cap > 0);

        hardParticipationCap = _cap;
    }

    /// @dev Fallback function that will delegate the request to create().
    function () external payable onlyDuringSale {
        create(msg.sender);
    }

    /// @dev Create and sell tokens to the caller.
    /// @param _recipient address The address of the recipient receiving the tokens.
    function create(address _recipient) public payable onlyDuringSale {
        require(_recipient != address(0));

        // Enforce participation cap (in Wei received).
        uint256 weiAlreadyParticipated = participationHistory[msg.sender];
        uint256 participationCap = SafeMath.min256(participationCaps[msg.sender], hardParticipationCap);
        uint256 cappedWeiReceived = SafeMath.min256(msg.value, participationCap.sub(weiAlreadyParticipated));
        require(cappedWeiReceived > 0);

        // Accept funds and transfer to funding recipient.
        uint256 weiLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold).div(KIN_PER_WEI);
        uint256 weiToParticipate = SafeMath.min256(cappedWeiReceived, weiLeftInSale);
        participationHistory[msg.sender] = weiAlreadyParticipated.add(weiToParticipate);
        fundingRecipient.transfer(weiToParticipate);

        // Issue tokens and transfer to recipient.
        uint256 tokensLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold);
        uint256 tokensToIssue = weiToParticipate.mul(KIN_PER_WEI);
        if (tokensLeftInSale.sub(tokensToIssue) < KIN_PER_WEI) {
            // If purchase would cause less than KIN_PER_WEI tokens left then nobody could ever buy them.
            // So, gift them to the last buyer.
            tokensToIssue = tokensLeftInSale;
        }
        tokensSold = tokensSold.add(tokensToIssue);
        issueTokens(_recipient, tokensToIssue);

        // Partial refund if full participation not possible
        // e.g. due to cap being reached.
        uint256 refund = msg.value.sub(weiToParticipate);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }

    /// @dev Finalizes the token sale event, by stopping token minting.
    function finalize() external onlyAfterSale onlyOwner {
        if (!kin.isMinting()) {
            revert();
        }

        require(lastGrantedIndex == tokenGrantees.length);

        // Finish minting.
        kin.endMinting();
    }

    /// @dev Grants pre-configured token grants in batches. When the method is called, it&#39;ll resume from the last grant,
    /// from its previous run, and will finish either after granting GRANT_BATCH_SIZE grants or finishing the whole list
    /// of grants.
    function grantTokens() external onlyAfterSale onlyOwner {
        uint endIndex = SafeMath.min256(tokenGrantees.length, lastGrantedIndex + GRANT_BATCH_SIZE);
        for (uint i = lastGrantedIndex; i < endIndex; i++) {
            address grantee = tokenGrantees[i];

            // Calculate how many tokens have been granted, vested, and issued such that: granted = vested + issued.
            TokenGrant memory tokenGrant = tokenGrants[grantee];
            uint256 tokensGranted = tokenGrant.value.mul(tokensSold).div(MAX_TOKENS_SOLD);
            uint256 tokensVesting = tokensGranted.mul(tokenGrant.percentVested).div(100);
            uint256 tokensIssued = tokensGranted.sub(tokensVesting);

            // Transfer issued tokens that have yet to be transferred to grantee.
            if (tokensIssued > 0) {
                issueTokens(grantee, tokensIssued);
            }

            // Transfer vested tokens that have yet to be transferred to vesting trustee, and initialize grant.
            if (tokensVesting > 0) {
                issueTokens(trustee, tokensVesting);
                trustee.grant(grantee, tokensVesting, now.add(tokenGrant.startOffset), now.add(tokenGrant.cliffOffset),
                    now.add(tokenGrant.endOffset), tokenGrant.installmentLength, true);
            }

            lastGrantedIndex++;
        }
    }

    /// @dev Issues tokens for the recipient.
    /// @param _recipient address The address of the recipient.
    /// @param _tokens uint256 The amount of tokens to issue.
    function issueTokens(address _recipient, uint256 _tokens) private {
        // Request Kin token contract to mint the requested tokens for the buyer.
        kin.mint(_recipient, _tokens);

        TokensIssued(_recipient, _tokens);
    }

    /// @dev Returns whether the sale has ended.
    /// @return bool Whether the sale has ended or not.
    function saleEnded() private constant returns (bool) {
        return tokensSold >= MAX_TOKENS_SOLD || now >= endTime;
    }

    /// @dev Requests to transfer control of the Kin token contract to a new owner.
    /// @param _newOwnerCandidate address The address to transfer ownership to.
    ///
    /// NOTE:
    ///   1. The new owner will need to call Kin token contract&#39;s acceptOwnership directly in order to accept the ownership.
    ///   2. Calling this method during the token sale will prevent the token sale to continue, since only the owner of
    ///      the Kin token contract can issue new tokens.
    function requestKinTokenOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        kin.requestOwnershipTransfer(_newOwnerCandidate);
    }

    /// @dev Accepts new ownership on behalf of the Kin token contract.
    // This can be used by the sale contract itself to claim back ownership of the Kin token contract.
    function acceptKinTokenOwnership() external onlyOwner {
        kin.acceptOwnership();
    }

    /// @dev Requests to transfer control of the VestingTrustee contract to a new owner.
    /// @param _newOwnerCandidate address The address to transfer ownership to.
    ///
    /// NOTE:
    ///   1. The new owner will need to call VestingTrustee&#39;s acceptOwnership directly in order to accept the ownership.
    ///   2. Calling this method during the token sale will prevent the token sale from finalizaing, since only the owner
    ///      of the VestingTrustee contract can issue new token grants.
    function requestVestingTrusteeOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        trustee.requestOwnershipTransfer(_newOwnerCandidate);
    }

    /// @dev Accepts new ownership on behalf of the VestingTrustee contract.
    /// This can be used by the token sale contract itself to claim back ownership of the VestingTrustee contract.
    function acceptVestingTrusteeOwnership() external onlyOwner {
        trustee.acceptOwnership();
    }
}