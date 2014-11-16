using Winston

function test_quad(p::Array{Float64, 2})
    println(p)
    p /= 8;
    x = zeros(640*480)
    y = zeros(640*480)
    a = zeros(9)
    denom = p[4,1]*(p[2,2] - p[3,2]) + p[2,1]*(p[3,2]-p[4,2]) + p[3,1]*(p[4,2] - p[2,2])
    a[3] = p[1,1]*denom*15
    a[6] = p[1,2]*denom*15
    a[9] = 15*denom;
    a[7] = ((p[1,1] - p[4,1])*(p[2,2] - p[3,2]) + (p[1,2]-p[4,2])*(p[3,1] - p[2,1]))*3
    a[8] = ((p[1,1] - p[2,1])*(p[3,2] - p[4,2]) + (p[1,2]-p[2,2])*(p[4,1] - p[3,1]))*4
    a[2] = a[8]*p[2,1] + 4*(p[4,1]-p[1,1])*denom;
    a[1] = a[7]*p[4,1] + 3*(p[2,1]-p[1,1])*denom;
    a[4] = a[7]*p[4,2] + 3*(p[4,2]-p[1,2])*denom;
    a[5] = a[8]*p[2,2] + 4*(p[2,2]-p[1,2])*denom;
    return a
end

function test_quad()
    p1 = rand(1:80, 4, 1)
    p2 = rand(1:60, 4, 1)
    p = [p1 p2]
    println(p)
    x = zeros(640*480)
    y = zeros(640*480)
    a = zeros(9)
    denom = p[4,1]*(p[2,2] - p[3,2]) + p[2,1]*(p[3,2]-p[4,2]) + p[3,1]*(p[4,2] - p[2,2])
    a[3] = p[1,1]*denom*15
    a[6] = p[1,2]*denom*15
    a[9] = 15*denom;
    a[7] = ((p[1,1] - p[4,1])*(p[2,2] - p[3,2]) + (p[1,2]-p[4,2])*(p[3,1] - p[2,1]))*3
    a[8] = ((p[1,1] - p[2,1])*(p[3,2] - p[4,2]) + (p[1,2]-p[2,2])*(p[4,1] - p[3,1]))*4
    a[2] = a[8]*p[2,1] + 4*(p[4,1]-p[1,1])*denom;
    a[1] = a[7]*p[4,1] + 3*(p[2,1]-p[1,1])*denom;
    a[4] = a[7]*p[4,2] + 3*(p[4,2]-p[1,2])*denom;
    a[5] = a[8]*p[2,2] + 4*(p[2,2]-p[1,2])*denom;
    return a
end

function test_run(n)
    max = zeros(9, 1)
    for i=1:n
        a = log2(abs(test_quad()))
        for j=1:9
            if (a[j] > max[j])
                max[j] = a[j]
            end
        end
    end
    return max
end
