// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../libraries/LibAppStorage.sol";
import "../interfaces/IERC20.sol";

contract DiamondTokenFacet is IERC20 {
    // Get a reference to the diamond storage
    function getStorage() internal pure returns (LibAppStorage.AppStorage storage) {
        return LibAppStorage.diamondStorage();
    }

    // Token metadata - kept as constants
    string private constant _name = "DiamondStake Token";
    string private constant _symbol = "DST";
    uint8 private constant _decimals = 18;

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        // Use the dedicated tokenTotalSupply field for total supply
        return getStorage().tokenTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        // Use the dedicated tokenBalances mapping for token balances
        return getStorage().tokenBalances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        // Use the tokenAllowances mapping from AppStorage
        return getStorage().tokenAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        
        // Update allowance
        LibAppStorage.AppStorage storage ds = getStorage();
        uint256 currentAllowance = ds.tokenAllowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        
        return true;
    }

    function mint(address to, uint256 amount) external virtual {
        require(to != address(0), "Cannot mint to zero address");

        // Update the AppStorage instead of local storage
        LibAppStorage.AppStorage storage ds = getStorage();
        ds.tokenBalances[to] += amount;  // Update token balances
        ds.tokenTotalSupply += amount;   // Update the total supply
        
        emit Transfer(address(0), to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // Get the AppStorage
        LibAppStorage.AppStorage storage ds = getStorage();
        
        uint256 senderBalance = ds.tokenBalances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        // Update balances in AppStorage
        ds.tokenBalances[sender] = senderBalance - amount;
        ds.tokenBalances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        // Update allowances in AppStorage
        LibAppStorage.AppStorage storage ds = getStorage();
        ds.tokenAllowances[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }
}
