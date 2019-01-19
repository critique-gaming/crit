local M = {}

function M.low_pass(cutoff)
  local RC = 1.0 / (cutoff * 2.0 * math.pi);
  return function (x, newX, dt)
    local alpha = dt / (dt + RC);
    return x + alpha * (newX - x);
  end
end

function M.high_pass(cutoff)
  local RC = 1.0 / (cutoff * 2.0 * math.pi);
  return function (y, dx, dt)
    local alpha = RC / (dt + RC);
    return alpha * (y + dx);
  end
end

return M
