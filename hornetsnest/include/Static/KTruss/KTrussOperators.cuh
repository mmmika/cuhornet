#pragma once

namespace hornets_nest {

struct Init {
    HostDeviceVar<KTrussData> kt;

    OPERATOR(Vertex& vertex) {
        vert_t           src = vertex.id();
        kt().is_active[src] = 1;
    }
};


struct FindUnderK {
    HostDeviceVar<KTrussData> kt;

    OPERATOR(Vertex& vertex) {
        vert_t src = vertex.id();

        if (kt().is_active[src] == 0)
            return;
        if (vertex.degree() == 0) {
            kt().is_active[src] = 0;
            return;
        }
        for (vert_t adj = 0; adj < vertex.degree(); adj++) {
            int   pos = kt().offset_array[src] + adj;
            if (kt().triangles_per_edge[pos] < (kt().max_K - 2)) {
                int       spot = atomicAdd((kt().counter), 1);
                kt().src[spot] = src;
                vert_t dest = vertex.neighbor_ptr()[adj];
                kt().dst[spot] = dest;
            }
        }
    }
};

struct getVertexSizes {
    int* sizes;

    OPERATOR(Vertex& vertex) {
        vert_t src = vertex.id();
        sizes[src] = vertex.degree();
    }
};


struct SimpleBubbleSort {

    OPERATOR(Vertex& vertex) {
        vert_t src = vertex.id();

        degree_t size = vertex.degree();
        for (vert_t i = 0; i < (size-1); i++) {
            vert_t min_idx=i;

            for(vert_t j=i+1; j<(size); j++){
                if(vertex.neighbor_ptr()[j]<vertex.neighbor_ptr()[min_idx])
                    min_idx=j;
            }
            vert_t temp = vertex.neighbor_ptr()[i];
            vertex.neighbor_ptr()[i] = vertex.neighbor_ptr()[min_idx];
            vertex.neighbor_ptr()[min_idx] = temp;
        }
 
    }
};


struct CountActive {
    HostDeviceVar<KTrussData> kt;

    OPERATOR(Vertex& vertex) {
        vert_t src = vertex.id();

        if (vertex.degree() == 0 && !kt().is_active[src])
            kt().is_active[src] = 0;
        else
            atomicAdd((kt().active_vertices), 1);
    }
};

} // namespace hornets_nest