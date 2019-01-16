pragma solidity ^0.4.24;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract StubeeEduCoin {
    // Public variables of the token
    // 토큰의 공용 변수
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    // 18개의 소수점이 강하게 제안된 기본값입니다. 변경하지 마십시오.

    uint256 public totalSupply;

    // This creates an array with all balances
    // 이렇게 하면 모든 밸런스를 가진 배열이 만들어집니다.
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    // 이렇게 하면 블록체인에 대해 고객에게 알릴 공개 이벤트가 생성됩니다.
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    // 이렇게 하면 블록체인에 대해 고객에게 알릴 공개 이벤트가 생성됩니다.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    // 이는 고객에게 연소된 양을 알려줍니다.
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     * 계약 작성자에게 초기 공급 토큰과 계약을 초기화합니다.
     */
    constructor (
        address fromAdd,
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {

        // Update total supply with the decimal amount
        // 총 공급량을 십진수로 업데이트합니다.
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        
        // Give the creator all initial tokens
        // 작성자에게 모든 초기 토큰 제공
        balanceOf[fromAdd] = totalSupply;                

        // Set the name for display purposes
        // 표시에 사용할 이름 설정
        name = tokenName;        

        // Set the symbol for display purposes
        // 표시 용도의 기호 설정                           
        symbol = tokenSymbol;                               
    }

    /**
     * Internal transfer, only can be called by this contract
     * 내부 이전, 이 계약에서만 호출할 수 있습니다.
     */
    function _transfer(address _from, address _to, uint _value) internal {

        // Prevent transfer to 0x0 address. Use burn() instead
        // 0x0 주소로 전송하지 마십시오. 대신 굽기()를 사용합니다.
        require(_to != 0x0);


        // Check if the sender has enough
        // 발신인이 충분한지 확인
        require(balanceOf[_from] >= _value);


        // Check for overflows
        // 오버플로우 확인
        require(balanceOf[_to] + _value >= balanceOf[_to]);


        // Save this for an assertion in the future
        // 향후 주장을 위해 저장
        uint previousBalances = balanceOf[_from] + balanceOf[_to];


        // Subtract from the sender
        // 발신자에서 빼기
        balanceOf[_from] -= _value;


        // Add the same to the recipient
        // 수신자에게 동일한 항목 추가
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);


        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        // 명령어는 정적 분석을 사용하여 코드의 버그를 찾는 데 사용됩니다. 그들은 절대 실패해서는 안된다.
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     * 당신의 계정에서 &#39;_value&#39; 토큰을 &#39;_to&#39;로 보냅니다.
     *
     * @param _to The address of the recipient(받는 사람의 주소)
     * @param _value the amount to send (송금액)
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     * &#39;_from&#39; 대신 `_value`토큰을 `_to`로 보냅니다.
     *
     * @param _from The address of the sender(보낸 사람의 주소)
     * @param _to The address of the recipient(받는 사람의 주소)
     * @param _value the amount to send(발송액)
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance(수당)
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     * `_spender`에서 귀하를 대신하여 `_value` 토큰만 사용하도록 허용합니다.
     *
     * @param _spender The address authorized to spend(사용 허가된 주소)
     * @param _value the max amount they can spend(그들이 지출할 수 있는 최대액)
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     * `_spender`가 귀하를 대신하여 `_value` 토큰을 사용한 후 계약을 할 수 있도록 허용
     *
     * @param _spender The address authorized to spend(사용 허가된 주소)
     * @param _value the max amount they can spend(그들이 지출할 수 있는 최대액)
     * @param _extraData some extra information to send to the approved contract(승인된 계약에 보낼 추가 정보)
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     * 시스템에서 `_value` 토큰을 복구할 수 없게 제거
     *
     * @param _value the amount of money to burn(태울 돈)
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough(보낸 사람이 충분한지 확인)
        balanceOf[msg.sender] -= _value;            // Subtract from the sender(보낸 사람에서 차감)
        totalSupply -= _value;                      // Updates totalSupply(총긍급량 업데이트)
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * `_from`대신하여 시스템에서 `_value` 토큰을 복구할 수 없게 제거
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough(목표 잔액이 충분한 지 확인)
        require(_value <= allowance[_from][msg.sender]);    // Check allowance(수당 확인)
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance(목표 잔액에서 차감)
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance(보낸 사람 수당에서 차감)
        totalSupply -= _value;                              // Update totalSupply(총긍급량 업데이트)
        emit Burn(_from, _value);
        return true;
    }
}