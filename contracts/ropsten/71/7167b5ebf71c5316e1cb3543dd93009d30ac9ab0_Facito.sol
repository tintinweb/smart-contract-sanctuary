pragma solidity ^0.4.24; // Set compiler version

// Token contract
contract Facito {
    string public constant name = "Facito"; // Name
    string public constant symbol = "FAC"; // Symbol
    uint8 public constant decimals = 18; // Set precision points
    uint256 public totalSupply; // Store total supply

    mapping(bytes32 => Article) public articles; // Store articles

    event Transfer (
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approve (
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event NewArticle (
        bytes32 _ID,
        address _author,
        string _title
    );

    event ReadArticle (
        bytes32 _ID,
        address _author,
        address _reader,
        string _title
    );

    struct Article {
        string Title;
        bytes32 ID;
        string Content;
        string HeaderSource;
        address Author;
        mapping(address => uint) UnspentOutputs;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) public {
        balanceOf[this] = _initialSupply; // Set contract balance
        totalSupply = _initialSupply; // Set total supply
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance"); // Check for invalid balance

        balanceOf[msg.sender] -= _value; // Set sender balance
        balanceOf[_to] += _value; // Set recipient balance

        emit Transfer(msg.sender, _to, _value); // Emit transfer event

        return true; // Return success
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value; // Set allowance

        emit Approve(msg.sender, _spender, _value); // Emit approve event

        return true; // Return success
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Insufficient balance"); // Check allowance is valid
        require(_value <= allowance[_from][msg.sender], "Insufficient balance"); // Check allowance is valid

        balanceOf[_from] -= _value; // Remove from sender
        balanceOf[_to] += _value; // Add to destination

        allowance[_from][msg.sender] -= _value; // Remove allowance

        emit Transfer(_from, _to, _value); // Emit transfer event

        return true; // Return success
    }

    function newArticle(string _title, string _content, string _headerSource) public returns (bool success) {
        bytes32 _id = keccak256(abi.encodePacked(_title, _content, _headerSource, msg.sender)); // Hash ID

        emit NewArticle(_id, msg.sender, _title); // Emit new article

        Article memory article = Article(_title, _id, _content, _headerSource, msg.sender); // Initialize article

        articles[keccak256(abi.encodePacked(_title, _content, _headerSource, msg.sender))] = article; // Push new article

        return true; // Return success
    }

    function readArticle(bytes32 _id) public returns (bool success) {
        require(articles[_id].UnspentOutputs[msg.sender] == 0, "Article already read"); // Check article hasn&#39;t already been read
        require(articles[_id].Author != msg.sender, "Author cannot read own article"); // Check author isn&#39;t reading own article

        emit ReadArticle(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit read article

        articles[_id].UnspentOutputs[msg.sender] = 1; // Set spent

        transfer(msg.sender, 10); // Transfer coins to reader
        transfer(articles[_id].Author, 10); // Transfer coins to author

        return true; // Return success
    }
}