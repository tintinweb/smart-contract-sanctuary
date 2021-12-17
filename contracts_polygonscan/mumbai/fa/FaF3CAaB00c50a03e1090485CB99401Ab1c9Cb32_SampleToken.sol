import "./ERC20.sol";

contract SampleToken is ERC20{
    constructor() ERC20("Sample Token", "SMT"){}
    function decimals() public view  override returns (uint8) {
        return 6;
    }
}