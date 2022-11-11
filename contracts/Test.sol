// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Test {
    using SafeERC20 for IERC20;

    address[] public routers;
    address[] public connectors;

    /**
        Gets router* and path* that give max output amount with input amount and tokens
        @param amountIn input amount
        @param tokenIn source token
        @param tokenOut destination token
        @return amountOut max output amount and router and path, that give this output amount
        @return router - Uniswap-like Router
        @return path - token list to swap
     */
    function quote(
        uint amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint amountOut, address router, address[] memory path) {
        (uint amountOut1, address router1, address connector) = _getBestForThree(amountIn, tokenIn, tokenOut);
        (uint amountOut2, address router2) = _getBestForTwo(amountIn, tokenIn, tokenOut);
        if(amountOut1 > amountOut2) {
            amountOut = amountOut1;
            router = router1;
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = connector;
            path[2] = tokenOut;
        } else {
            amountOut = amountOut2;
            router = router2;
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
        }
    }
    
    /**
        Swaps tokens on router with path, should check slippage
        @param amountIn input amount
        @param amountOutMin minumum output amount
        @param router Uniswap-like router to swap tokens on
        @param path tokens list to swap
        @return amountOut actual output amount
     */
    function swap(
        uint amountIn,
        uint amountOutMin,
        address router,
        address[] memory path
    ) external returns (uint amountOut) {
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).safeApprove(router, amountIn);
        uint[] memory amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );
        amountOut = amounts[amounts.length - 1];
    }

    function _getBestForTwo(uint amountIn, address tokenIn, address tokenOut) internal view returns(uint amountOut, address router) {
        address[] memory _path = new address[](2);
        _path[0] = tokenIn;
        _path[1] = tokenOut;
        for(uint i = 0; i < routers.length; i++) {
            uint outPrice = (IUniswapV2Router02(routers[i]).getAmountsOut(amountIn, _path))[0];
            if(outPrice > amountOut) {
                amountOut = outPrice;
                router = routers[i];
            } 
        }
    }

    function _getBestForThree(
        uint amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns(uint amountOut, address router, address connector) {
        address[] memory _path = new address[](3);
        _path[0] = tokenIn;
        _path[2] = tokenOut;
        address bestConnector;
        for(uint i = 0; i < routers.length; i++) {
            uint bestPrice;
            for(uint j = 0; j < connectors.length; j++) {
                _path[1] = connectors[j];
                uint outPrice = (IUniswapV2Router02(routers[i]).getAmountsOut(amountIn, _path))[1];
                if (outPrice > bestPrice) {
                    bestPrice = outPrice;
                    bestConnector = connectors[j];
                }
            }
            if(bestPrice > amountOut) {
                amountOut = bestPrice;
                router = routers[i];
                connector = bestConnector;
            } 
        }
    }
}