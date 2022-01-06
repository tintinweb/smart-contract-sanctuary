/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-05
*/

pragma solidity >0.5.0;

		contract Greeter {
			string public greeting;

			constructor() public {
				greeting = 'Hello';
			}

			function setGreeting(string memory _greeting) public {
				greeting = _greeting;
			}

			function greet() view public returns (string memory) {
				return greeting;
			}
		}