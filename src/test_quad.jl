using Winston

function test_quad(p::Array{Int64, 2})
    println(p)
    x = zeros(640*480)
    y = zeros(640*480)
    a = zeros(9)
    b = zeros(9)
    denom = p[4,1]*(p[2,2] - p[3,2]) + p[2,1]*(p[3,2]-p[4,2]) + p[3,1]*(p[4,2] - p[2,2])
    a[3] = p[1,1]*denom*1920
    a[6] = p[1,2]*denom*1920
    a[9] = 1920*denom
    a[7] = ((p[1,1] - p[4,1])*(p[2,2] - p[3,2]) + (p[1,2]-p[4,2])*(p[3,1] - p[2,1]))*3
    a[8] = ((p[1,1] - p[2,1])*(p[3,2] - p[4,2]) + (p[1,2]-p[2,2])*(p[4,1] - p[3,1]))*4
    a[2] = a[8]*p[2,1] + 4*(p[4,1]-p[1,1])*denom
    a[1] = a[7]*p[4,1] + 3*(p[2,1]-p[1,1])*denom
    a[4] = a[7]*p[4,2] + 3*(p[4,2]-p[1,2])*denom
    a[5] = a[8]*p[2,2] + 4*(p[2,2]-p[1,2])*denom
    b[1] = a[6]*a[8] - a[5]*a[9]
    b[2] = a[2]*a[9] - a[3]*a[8]
    b[3] = a[3]*a[5] - a[2]*a[6]
    b[4] = a[4]*a[9] - a[6]*a[7]
    b[5] = a[3]*a[7] - a[1]*a[9]
    b[6] = a[1]*a[6] - a[3]*a[4]
    b[7] = a[5]*a[7] - a[4]*a[8]
    b[8] = a[1]*a[8] - a[2]*a[7]
    b[9] = a[2]*a[4] - a[1]*a[5]
    count = 1
    for i=1:640
        for j=1:480
            x[count], y[count] = pixel_map(i, j, a)
            count += 1
        end
    end
    p = plot(x, y)
    display(p)
    return a, b
end

function pixel_map(x,y, a::Array{Float64, 1})
    x_out = (a[1]*x + a[2]*y + a[3])/(a[7]*x + a[8]*y + a[9])
    y_out = (a[4]*x + a[5]*y + a[6])/(a[7]*x + a[8]*y + a[9])
    return x_out, y_out
end

function test_quad()
    p1 = rand(1:640, 4, 1)
    p2 = rand(1:480, 4, 1)
    p = [p1 p2]
    println(p)
    a, b = test_quad(p)
    return a, b
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
