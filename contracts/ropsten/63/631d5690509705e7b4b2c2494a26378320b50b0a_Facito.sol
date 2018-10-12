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
        bytes32 _id = keccak256(abi.encodePacked(_title, _content, _headerSource, msg.sender, block.timestamp)); // Hash ID

        emit NewArticle(_id, msg.sender, _title); // Emit new article

        Article memory article = Article(_title, _id, _content, _headerSource, msg.sender); // Initialize article

        articles[_id] = article; // Push new article

        return true; // Return success
    }

    function readArticle(bytes32 _id) public returns (bool success) {
        require(articles[_id].UnspentOutputs[msg.sender] != 1, "Article already read"); // Check article hasn&#39;t already been read
        require(articles[_id].Author != msg.sender, "Author cannot read own article"); // Check author isn&#39;t reading own article

        emit ReadArticle(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit read article

        articles[_id].UnspentOutputs[msg.sender] = 1; // Set spent

        transfer(msg.sender, (balanceOf[this]/totalSupply)*2); // Transfer coins to reader
        transfer(articles[_id].Author, (balanceOf[this]/totalSupply)*10); // Transfer coins to author

        return true; // Return success
    }

    function hexStrToBytes(string hex_str) public pure returns (bytes) {
        //Check hex string is valid
        if (bytes(hex_str)[0]!=&#39;0&#39; ||
            bytes(hex_str)[1]!=&#39;x&#39; ||
            bytes(hex_str).length%2!=0 ||
            bytes(hex_str).length < 4) {
                revert();
        }

        bytes memory bytes_array = new bytes((bytes(hex_str).length-2)/2);

        for (uint i=2;i<bytes(hex_str).length;i+=2) {
            uint tetrad1=16;
            uint tetrad2=16;

            //left digit
            if (uint(bytes(hex_str)[i])>=48 &&uint(bytes(hex_str)[i])<=57)
                tetrad1=uint(bytes(hex_str)[i])-48;

            //right digit
            if (uint(bytes(hex_str)[i+1])>=48 &&uint(bytes(hex_str)[i+1])<=57)
                tetrad2=uint(bytes(hex_str)[i+1])-48;

            //left A->F
            if (uint(bytes(hex_str)[i])>=65 &&uint(bytes(hex_str)[i])<=70)
                tetrad1=uint(bytes(hex_str)[i])-65+10;

            //right A->F
            if (uint(bytes(hex_str)[i+1])>=65 &&uint(bytes(hex_str)[i+1])<=70)
                tetrad2=uint(bytes(hex_str)[i+1])-65+10;

            //left a->f
            if (uint(bytes(hex_str)[i])>=97 &&uint(bytes(hex_str)[i])<=102)
                tetrad1=uint(bytes(hex_str)[i])-97+10;

            //right a->f
            if (uint(bytes(hex_str)[i+1])>=97 &&uint(bytes(hex_str)[i+1])<=102)
                tetrad2=uint(bytes(hex_str)[i+1])-97+10;

            //Check all symbols are allowed
            if (tetrad1==16 || tetrad2==16)
                revert();

            bytes_array[i/2-1]=byte(16*tetrad1+tetrad2);
        }
        return bytes_array;
    }
}