#=
This script generates an accel_lut.v file.
accel_lut.v contains a verilog implementation of a lookup table,
which takes in an accelerometer reading (6 bit x dir, 6 bit y dir),
and looks up a 76 bit value (4 corners of quadrilateral)
This script requires a input file accel_lut.txt containing data points.
It then interpolates the data points using 2D splines,
and creates the desired lookup table.

Format of accel_lut.txt:
x_accel, y_accel, x1, y1, x2, y2, x3, y3, x4, y4

i.e it is a csv file, each line denoting a reading
for ease of entry, all values are hex (just read off hex display)
leading zeros don't have to be specified, but can be if desired

NOTE: accel_lut.v and accel_lut.txt are suggested names
General installation:
1) Install julia
2) open Julia interpreter, i.e julia at cmd line
3) install gfortran (gcc frontend for fortran), needed to compile interpolation package
4) install Dierckx (for the spline interpolation) by `Pkg.add("Dierckx")' at julia prompt
5) Dierckx details (docs, installation help, etc): https://github.com/kbarbary/Dierckx.jl

General usage:
accel_lut(input_path, output_path) at julia prompt

input_path is path to the csv file, and output_path is path to the desired .v file
NOTE: in order to run the command, you first need to include this file, so type:
include("accel_lut.jl") at the julia prompt prior to running the above
NOTE: THIS CODE WILL OVERWRITE THE FILE AT OUTPUT_PATH!!!

Suggested usage:
accel_lut("./accel_lut.txt", "./accel_lut.v")
=#

using Dierckx # interpolation package

function read_file(path)
    return readcsv(path, String)
end

function parse_data(path)
    raw_data = read_file(path)
    num_samples = size(raw_data)[1]
    x_accel = zeros(Int64, num_samples)
    y_accel = zeros(Int64, num_samples)
    x1 = zeros(Int64, num_samples)
    y1 = zeros(Int64, num_samples)
    x2 = zeros(Int64, num_samples)
    y2 = zeros(Int64, num_samples)
    x3 = zeros(Int64, num_samples)
    y3 = zeros(Int64, num_samples)
    x4 = zeros(Int64, num_samples)
    y4 = zeros(Int64, num_samples)
    for i = 1:num_samples
        x_accel[i] = parseint(raw_data[i,1])
        y_accel[i] = parseint(raw_data[i,2])
        x1[i] = parseint(raw_data[i,3])
        y1[i] = parseint(raw_data[i,4])
        x2[i] = parseint(raw_data[i,5])
        y2[i] = parseint(raw_data[i,6])
        x3[i] = parseint(raw_data[i,7])
        y3[i] = parseint(raw_data[i,8])
        x4[i] = parseint(raw_data[i,9])
        y4[i] = parseint(raw_data[i,10])
    end
    return float(x_accel), float(y_accel), float(x1), float(y1), float(x2), float(y2), float(x3), float(y3), float(x4), float(y4)
end

function saturate!(vec, low, upp)
    for i=1:length(vec)
        if (vec[i] < low)
            vec[i] = low
        elseif (vec[i] > upp)
            vec[i] = upp
        end
    end
    return vec
end

function write_file(path, x_accel, y_accel, x1, y1, x2, y2, x3, y3, x4, y4)
    # compute grid
    x = zeros(2^12)
    y = zeros(2^12)
    quad_corners = zeros(Int128, 2^12)
    for i=0:2^12-1
        x[i+1] = i >> 6
        y[i+1] = i & ((1 << 6) - 1)
    end

    # do the spline interpolation
    # we do linear fits for now
    # as we add more points, we can do something more sophisticated
    x_deg = 1;
    y_deg = 1;
    # we also use a smoothing factor
    # this trades off exact interpolation vs weighted least squares
    # for more details, see doc at: https://github.com/kbarbary/Dierckx.jl
    smooth_factor = 0.0;
    spline_x1 = Spline2D(x_accel, y_accel, x1; kx=x_deg, ky=y_deg, s=smooth_factor)
    spline_x2 = Spline2D(x_accel, y_accel, x2; kx=x_deg, ky=y_deg, s=smooth_factor)
    spline_x3 = Spline2D(x_accel, y_accel, x3; kx=x_deg, ky=y_deg, s=smooth_factor)
    spline_x4 = Spline2D(x_accel, y_accel, x4; kx=x_deg, ky=y_deg, s=smooth_factor)
    spline_y1 = Spline2D(x_accel, y_accel, y1; kx=x_deg, ky=y_deg, s=smooth_factor)
    spline_y2 = Spline2D(x_accel, y_accel, y2; kx=x_deg, ky=y_deg, s=smooth_factor)
    spline_y3 = Spline2D(x_accel, y_accel, y3; kx=x_deg, ky=y_deg, s=smooth_factor)
    spline_y4 = Spline2D(x_accel, y_accel, y4; kx=x_deg, ky=y_deg, s=smooth_factor)
    x1_interp = integer(evaluate(spline_x1, x, y))
    x2_interp = integer(evaluate(spline_x2, x, y))
    x3_interp = integer(evaluate(spline_x3, x, y))
    x4_interp = integer(evaluate(spline_x4, x, y))
    y1_interp = integer(evaluate(spline_y1, x, y))
    y2_interp = integer(evaluate(spline_y2, x, y))
    y3_interp = integer(evaluate(spline_y3, x, y))
    y4_interp = integer(evaluate(spline_y4, x, y))

    # threshold x, y coords at appropriate values
    # this is to guarantee we are not putting garbage into the lut
    low_x = 0
    low_y = 0
    upp_x = 639
    upp_y = 479
    saturate!(x1_interp, low_x, upp_x)
    saturate!(x2_interp, low_x, upp_x)
    saturate!(x3_interp, low_x, upp_x)
    saturate!(x4_interp, low_x, upp_x)
    saturate!(y1_interp, low_y, upp_y)
    saturate!(y2_interp, low_y, upp_y)
    saturate!(y3_interp, low_y, upp_y)
    saturate!(y4_interp, low_y, upp_y)

    # compute quad_corners
    for i=1:2^12
        quad_corners[i] = y4_interp[i] + (x4_interp[i] << 9) + (y3_interp[i] << 19) + (x3_interp[i] << 28)
        quad_corners[i] += (y2_interp[i] << 38) + (x2_interp[i] << 47) + (y1_interp[i] << 57) + (x1_interp[i] << 66)
    end

    # write header
    comment_head = "////////////////////////////////////////////////////////////////////////////////\n"
    comment_body1 = "//This file was autogenerated by accel_lut.jl.\n"
    comment_body2 = "//DO NOT MANUALLY EDIT THIS FILE!!!\n\n"
    comment_body3 = "//This file implements accel_lut rom for lookup of quadrilateral corners\n//based on accelerometer readings\n"
    comment_tail = "////////////////////////////////////////////////////////////////////////////////\n\n"
    code_preamble1 = "module accel_lut(input clk, input[11:0] accel_val, output reg[75:0] quad_corners);\n"
    code_preamble2 = "always @(posedge clk) begin\n"
    code_preamble3 = "\tcase (accel_val)\n";
    fs = open(path, "w")
    write(fs, string(comment_head, comment_body1, comment_body2, comment_body3, comment_tail, code_preamble1, code_preamble2, code_preamble3))

    # write body
    for i=0:2^12-1
        val = quad_corners[i+1]
        line_str = string("\t\t12'd", i, ": quad_corners = 76'd", val, ";\n")
        write(fs, line_str)
    end

    # write footer
    code_end = "\tendcase\nend\nendmodule"
    write(fs, code_end)
    close(fs)
end

function accel_lut(in_path, out_path)
    x_accel, y_accel, x1, y1, x2, y2, x3, y3, x4, y4 = parse_data(in_path)
    write_file(out_path, x_accel, y_accel, x1, y1, x2, y2, x3, y3, x4, y4)
end
